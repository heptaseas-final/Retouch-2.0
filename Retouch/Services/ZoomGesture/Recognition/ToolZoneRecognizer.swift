import CoreGraphics

nonisolated struct ToolZoneReading: Equatable {
    var eyeTriggerLeft = false
    var eyeTriggerRight = false
    var eyeHoldLeft = false
    var eyeHoldRight = false
    var lipsTrigger = false
    var lipsHold = false
    var isInZone = false
}

nonisolated struct ToolZoneRecognizer {
    let points: FacePoints
    let tools: [TrackedTool]
    let enterDistance: Double
    let maxIntentSpeed: CGFloat
    let noseActive: Bool
    let support: Bool

    func read() -> ToolZoneReading {
        var reading = ToolZoneReading()
        readEyes(into: &reading)
        readLips(into: &reading)
        return reading
    }

    private var triggerScale: CGFloat {
        min(CGFloat(enterDistance / ZoomTuning.handEnterDistance), 1.1)
    }

    private func readEyes(into reading: inout ToolZoneReading) {
        guard var zones = EyeZones(points: points),
              let left = points.leftEye, let right = points.rightEye else { return }
        zones.triggerScale = triggerScale
        var noseZones = NoseZones(points: points)
        noseZones?.triggerScale = triggerScale

        for tool in tools where tool.label != .lip {
            guard tool.confidence >= ToolDetectionTuning.minConfidence else { continue }
            let center = tool.center
            let nearLeft = Self.nearest(tool.rect, to: left)
            let nearRight = Self.nearest(tool.rect, to: right)

            if zones.holds(.left, at: nearLeft) {
                reading.eyeHoldLeft = true
                reading.isInZone = true
            }
            if zones.holds(.right, at: nearRight) {
                reading.eyeHoldRight = true
                reading.isInZone = true
            }

            guard tool.confidence >= ToolDetectionTuning.triggerConfidence,
                  !zones.isLipsSide(center),
                  !claimedByNose(center, noseZones) else { continue }
            let leftValue = zones.gripValue(nearLeft, to: .left)
            let rightValue = zones.gripValue(nearRight, to: .right)
            var side: EyeSide?
            if leftValue <= 1, leftValue <= rightValue {
                side = .left
            } else if rightValue <= 1 {
                side = .right
            }
            guard let side else { continue }
            reading.isInZone = true
            guard tool.speed < maxIntentSpeed else { continue }
            if side == .left { reading.eyeTriggerLeft = true } else { reading.eyeTriggerRight = true }
        }
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

        let base = CGFloat(ZoomTuning.handEnterDistance)
        let holdRx = base * ZoomTuning.lipsTriggerStretchX * ZoomTuning.lipsHoldScale
        let holdRy = base * ZoomTuning.lipsTriggerStretchY * ZoomTuning.lipsHoldScale
        var limit = CGFloat(enterDistance)
        if support { limit *= ZoomTuning.pitchLipsReach }
        let rx = limit * ZoomTuning.lipsTriggerStretchX
        let ry = limit * ZoomTuning.lipsTriggerStretchY

        for tool in tools where tool.label != .eye {
            guard tool.confidence >= ToolDetectionTuning.minConfidence else { continue }
            let center = tool.center
            let near = Self.nearest(tool.rect, to: lips)
            if holdOwnedByLips(center), inOval(near, rx: holdRx, ry: holdRy) {
                reading.lipsHold = true
                reading.isInZone = true
            }
            guard tool.confidence >= ToolDetectionTuning.triggerConfidence,
                  ownedByLips(center), inOval(near, rx: rx, ry: ry) else { continue }
            reading.isInZone = true
            if tool.speed < maxIntentSpeed { reading.lipsTrigger = true }
        }
    }

    private func claimedByNose(_ p: CGPoint, _ zones: NoseZones?) -> Bool {
        guard let zones else { return false }
        if noseActive { return zones.holds(p) }
        return zones.owns(p) && zones.inTrigger(p)
    }

    private static func nearest(_ rect: CGRect, to p: CGPoint) -> CGPoint {
        CGPoint(x: min(max(p.x, rect.minX), rect.maxX), y: min(max(p.y, rect.minY), rect.maxY))
    }
}
