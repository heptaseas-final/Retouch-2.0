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
    private enum Zone { case leftEye, rightEye, nose }

    let points: FacePoints
    let tools: [TrackedTool]
    let enterDistance: Double
    let maxIntentSpeed: CGFloat
    let noseActive: Bool
    let support: Bool

    func read() -> ToolZoneReading {
        var reading = ToolZoneReading()
        readEyesAndNose(into: &reading)
        readLips(into: &reading)
        return reading
    }

    private var triggerScale: CGFloat {
        min(CGFloat(enterDistance / ZoomTuning.handEnterDistance), ZoomTuning.maxTriggerScale)
    }

    private func readEyesAndNose(into reading: inout ToolZoneReading) {
        guard var zones = EyeZones(points: points),
              let left = points.leftEye, let right = points.rightEye else { return }
        zones.triggerScale = triggerScale
        var noseZones = NoseZones(points: points)
        noseZones?.triggerScale = triggerScale

        for tool in tools where tool.label != .lip {
            guard tool.confidence >= ToolDetectionTuning.minConfidence else { continue }
            let nearLeft = Self.nearest(tool.rect, to: left)
            let nearRight = Self.nearest(tool.rect, to: right)
            let brushNose = tool.label == .brush ? noseZones : nil
            let nearNose = points.nose.map { Self.nearest(tool.rect, to: $0) }

            if zones.holds(.left, at: nearLeft, grip: true) {
                reading.eyeHoldLeft = true
                reading.isInZone = true
            }
            if zones.holds(.right, at: nearRight, grip: true) {
                reading.eyeHoldRight = true
                reading.isInZone = true
            }
            if let brushNose, let nearNose, brushNose.holds(nearNose) {
                reading.noseHold = true
                reading.isInZone = true
            }
            if tool.speed >= maxIntentSpeed { reading.fastTool = true }

            guard tool.confidence >= ToolDetectionTuning.triggerConfidence,
                  !zones.isLipsSide(tool.center) else { continue }
            let extra = [nearLeft, nearRight] + (nearNose.map { [$0] } ?? [])
            guard let zone = dominantZone(tool.rect, extra: extra, eyes: zones, nose: brushNose) else { continue }
            reading.isInZone = true
            guard tool.speed < maxIntentSpeed else { continue }
            switch zone {
            case .leftEye: reading.eyeTriggerLeft = true
            case .rightEye: reading.eyeTriggerRight = true
            case .nose: reading.noseTrigger = true
            }
        }
    }

    private func dominantZone(_ rect: CGRect, extra: [CGPoint], eyes: EyeZones, nose: NoseZones?) -> Zone? {
        var counts: [Zone: Int] = [:]
        let steps = ToolDetectionTuning.coverageSamples
        var samples = extra
        for i in 0..<steps {
            for j in 0..<steps {
                let fx = (CGFloat(i) + 0.5) / CGFloat(steps)
                let fy = (CGFloat(j) + 0.5) / CGFloat(steps)
                samples.append(CGPoint(x: rect.minX + rect.width * fx, y: rect.minY + rect.height * fy))
            }
        }
        for p in samples {
            guard let zone = zone(of: p, eyes: eyes, nose: nose) else { continue }
            counts[zone, default: 0] += 1
        }
        let order: [Zone] = [.leftEye, .rightEye, .nose]
        return order.filter { (counts[$0] ?? 0) > 0 }.max { (counts[$0] ?? 0) < (counts[$1] ?? 0) }
    }

    private func zone(of p: CGPoint, eyes: EyeZones, nose: NoseZones?) -> Zone? {
        if noseActive, let nose, nose.holds(p) { return .nose }
        if let side = eyes.gripTriggerEye(at: p) { return side == .left ? .leftEye : .rightEye }
        if let nose, nose.inTrigger(p) { return .nose }
        return nil
    }

    private func readLips(into reading: inout ToolZoneReading) {
        let width = points.width
        guard width > 0, let lips = points.lips else { return }
        let eyes = [points.leftEye, points.rightEye].compactMap { $0 }
        let zones = EyeZones(points: points)

        func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
        func ownedByLips(_ p: CGPoint) -> Bool {
            if let zones { return zones.isLipsSide(p) }
            return dist(p, lips) < (eyes.map { dist(p, $0) }.min() ?? .infinity)
        }
        func holdOwnedByLips(_ p: CGPoint) -> Bool {
            if let zones { return zones.isLipsHoldSide(p) }
            return ownedByLips(p)
        }
        let axisU = zones?.axisU ?? CGPoint(x: 1, y: 0)
        let axisV = zones?.axisV ?? CGPoint(x: 0, y: 1)
        func inOval(_ p: CGPoint, rx: CGFloat, ry: CGFloat) -> Bool {
            let dx = p.x - lips.x, dy = p.y - lips.y
            let a = (dx * axisU.x + dy * axisU.y) / width
            let b = (dx * axisV.x + dy * axisV.y) / width
            return hypot(a / rx, b / ry) < 1
        }

        var limit = CGFloat(enterDistance)
        if support { limit *= ZoomTuning.pitchLipsReach }
        let rx = limit * ZoomTuning.lipsTriggerStretchX
        let ry = limit * ZoomTuning.lipsTriggerStretchY
        let holdRx = rx * ZoomTuning.lipsHoldScale
        let holdRy = ry * ZoomTuning.lipsHoldScale

        for tool in tools where tool.label != .eye {
            guard tool.confidence >= ToolDetectionTuning.minConfidence else { continue }
            let center = tool.center
            let near = Self.nearest(tool.rect, to: lips)
            if holdOwnedByLips(center), inOval(near, rx: holdRx, ry: holdRy) {
                reading.lipsHold = true
                reading.isInZone = true
            }
            if tool.speed >= maxIntentSpeed { reading.fastTool = true }
            guard tool.confidence >= ToolDetectionTuning.triggerConfidence,
                  ownedByLips(center), inOval(near, rx: rx, ry: ry) else { continue }
            reading.isInZone = true
            if tool.speed < maxIntentSpeed { reading.lipsTrigger = true }
        }
    }

    private static func nearest(_ rect: CGRect, to p: CGPoint) -> CGPoint {
        CGPoint(x: min(max(p.x, rect.minX), rect.maxX), y: min(max(p.y, rect.minY), rect.maxY))
    }
}
