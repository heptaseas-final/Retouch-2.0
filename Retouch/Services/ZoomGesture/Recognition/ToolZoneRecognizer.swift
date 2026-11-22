import CoreGraphics

nonisolated struct ToolZoneReading: Equatable {
    var eyeTriggerLeft = false
    var eyeTriggerRight = false
    var eyeHoldLeft = false
    var eyeHoldRight = false
    var lipsTrigger = false
    var lipsHold = false
    var noseTrigger = false
    var noseHold = false
    var cheekTriggerLeft = false
    var cheekTriggerRight = false
    var cheekHoldLeft = false
    var cheekHoldRight = false
    var fastTool = false
    var isInZone = false
}

nonisolated struct ToolZoneRecognizer {
    let points: FacePoints
    let tools: [TrackedTool]
    let enterDistance: Double
    let maxIntentSpeed: CGFloat
    let locked: FaceZone?
    let support: Bool

    func read() -> ToolZoneReading {
        var reading = ToolZoneReading()
        guard let map = FaceZoneMap(points: points) else { return reading }
        for tool in tools where tool.confidence >= ToolDetectionTuning.minConfidence {
            let tip = ToolTipLocator.tip(of: tool, face: points)
            let probes = [tip] + (tool.tipHint.map { [$0] } ?? [])
            if tool.speed >= maxIntentSpeed { reading.fastTool = true }
            for zone in FaceZone.allCases where probes.contains(where: { map.holds(zone, at: $0) }) {
                Self.markHold(zone, in: &reading)
                if zone == locked { reading.isInZone = true }
            }
            guard let zone = map.zone(primary: tip, others: tool.tipHint.map { [$0] } ?? [], locked: locked) else { continue }
            reading.isInZone = true
            guard tool.confidence >= ToolDetectionTuning.triggerConfidence,
                  tool.speed < maxIntentSpeed else { continue }
            Self.markTrigger(zone, in: &reading)
        }
        return reading
    }

    private static func markHold(_ zone: FaceZone, in reading: inout ToolZoneReading) {
        switch zone {
        case .leftEye: reading.eyeHoldLeft = true
        case .rightEye: reading.eyeHoldRight = true
        case .nose: reading.noseHold = true
        case .lips: reading.lipsHold = true
        case .leftCheek: reading.cheekHoldLeft = true
        case .rightCheek: reading.cheekHoldRight = true
        }
    }

    private static func markTrigger(_ zone: FaceZone, in reading: inout ToolZoneReading) {
        switch zone {
        case .leftEye: reading.eyeTriggerLeft = true
        case .rightEye: reading.eyeTriggerRight = true
        case .nose: reading.noseTrigger = true
        case .lips: reading.lipsTrigger = true
        case .leftCheek: reading.cheekTriggerLeft = true
        case .rightCheek: reading.cheekTriggerRight = true
        }
    }
}
