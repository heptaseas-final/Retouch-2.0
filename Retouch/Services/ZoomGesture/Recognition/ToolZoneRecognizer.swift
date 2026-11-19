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
        guard let map = FaceZoneMap(points: points, reach: reach, lipsReach: lipsReach) else { return reading }
        for tool in tools where tool.confidence >= ToolDetectionTuning.minConfidence {
            let tip = ToolTipLocator.tip(of: tool.rect, face: points)
            let allowed = Self.zones(for: tool.label)
            if tool.speed >= maxIntentSpeed { reading.fastTool = true }
            for zone in allowed where map.holds(zone, at: tip) {
                Self.markHold(zone, in: &reading)
                if zone == locked { reading.isInZone = true }
            }
            guard let zone = map.zone(of: tip, locked: locked), allowed.contains(zone) else { continue }
            reading.isInZone = true
            guard tool.confidence >= ToolDetectionTuning.triggerConfidence,
                  tool.speed < maxIntentSpeed else { continue }
            Self.markTrigger(zone, in: &reading)
        }
        return reading
    }

    private var reach: CGFloat {
        min(CGFloat(enterDistance / ZoomTuning.handEnterDistance), ZoomTuning.maxTriggerScale)
    }

    private var lipsReach: CGFloat {
        CGFloat(enterDistance) * (support ? ZoomTuning.pitchLipsReach : 1)
    }

    private static func zones(for label: ToolDetection.Label) -> [FaceZone] {
        switch label {
        case .eye: [.leftEye, .rightEye]
        case .lip: [.lips]
        case .brush: FaceZone.allCases
        }
    }

    private static func markHold(_ zone: FaceZone, in reading: inout ToolZoneReading) {
        switch zone {
        case .leftEye: reading.eyeHoldLeft = true
        case .rightEye: reading.eyeHoldRight = true
        case .nose: reading.noseHold = true
        case .lips: reading.lipsHold = true
        }
    }

    private static func markTrigger(_ zone: FaceZone, in reading: inout ToolZoneReading) {
        switch zone {
        case .leftEye: reading.eyeTriggerLeft = true
        case .rightEye: reading.eyeTriggerRight = true
        case .nose: reading.noseTrigger = true
        case .lips: reading.lipsTrigger = true
        }
    }
}
