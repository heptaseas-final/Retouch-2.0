import CoreGraphics

nonisolated struct ZoomReadiness {
    let hands: [TrackedHand]
    let scan: HandScan
    let converter: CoordinateConverter
    let handProfile: HandProfile
    let maxIntentSpeed: CGFloat
    let locked: FaceZone?

    static func applying(_ tools: ToolZoneReading, to input: EyeZoomFlow.Input) -> EyeZoomFlow.Input {
        var result = input
        result.toolLeft = tools.eyeTriggerLeft
        result.toolRight = tools.eyeTriggerRight
        result.holdLeft = input.holdLeft || tools.eyeHoldLeft
        result.holdRight = input.holdRight || tools.eyeHoldRight
        result.toolHoldLeft = tools.eyeHoldLeft
        result.toolHoldRight = tools.eyeHoldRight
        result.handMovingAway = input.handMovingAway || tools.fastTool
        return result
    }

    static func applying(_ tools: ToolZoneReading, to input: LipsZoomFlow.Input) -> LipsZoomFlow.Input {
        var result = input
        result.toolReady = tools.lipsTrigger
        result.fingerNear = input.fingerNear || tools.lipsHold
        result.handMovingAway = input.handMovingAway || tools.fastTool
        return result
    }

    static func applying(_ tools: ToolZoneReading, to input: NoseZoomFlow.Input) -> NoseZoomFlow.Input {
        var result = input
        result.toolReady = tools.noseTrigger
        result.fingerNear = input.fingerNear || tools.noseHold
        result.handMovingAway = input.handMovingAway || tools.fastTool
        return result
    }

    func eye(points: FacePoints, support: Bool) -> EyeZoomFlow.Input {
        var input = EyeZoomFlow.Input()
        input.handLost = scan.handsSeen == 0 && hands.isEmpty
        input.handMovingAway = hands.contains { $0.speed >= maxIntentSpeed }
        guard points.width > 0, let map = map(points, support: support) else { return input }
        if support { input.enterDwellFactor = ZoomTuning.pitchEyeDwellFactor }

        for h in hands where (h.hasPose || h.holding) && h.speed < maxIntentSpeed {
            switch zone(of: h, map) {
            case .leftEye:
                if h.hasPose { input.poseLeft = true }
                if h.holding { input.gripLeft = true }
            case .rightEye:
                if h.hasPose { input.poseRight = true }
                if h.holding { input.gripRight = true }
            default: break
            }
        }
        switch leadZone(map, points) {
        case .leftEye: input.pointLeft = true
        case .rightEye: input.pointRight = true
        default: break
        }
        for p in hands.map(\.point) {
            if map.holds(.leftEye, at: p) { input.holdLeft = true }
            if map.holds(.rightEye, at: p) { input.holdRight = true }
        }
        return input
    }

    func lips(points: FacePoints, support: Bool) -> LipsZoomFlow.Input {
        var input = LipsZoomFlow.Input()
        input.handLost = scan.handsSeen == 0 && hands.isEmpty
        input.handMovingAway = hands.contains { $0.speed >= maxIntentSpeed }
        guard points.width > 0, let map = map(points, support: support) else { return input }

        for h in hands where (h.hasPose || h.holding) && h.speed < maxIntentSpeed && zone(of: h, map) == .lips {
            if h.pose2 { input.pose2Ready = true }
            if h.pose3 { input.pose3Ready = true }
            if h.holding { input.gripReady = true }
        }
        input.pointReady = leadZone(map, points) == .lips
        input.fingerNear = hands.contains { map.holds(.lips, at: $0.point) }
        return input
    }

    func nose(points: FacePoints, support: Bool) -> NoseZoomFlow.Input {
        var input = NoseZoomFlow.Input()
        input.handLost = scan.handsSeen == 0 && hands.isEmpty
        input.handMovingAway = hands.contains { $0.speed >= maxIntentSpeed }
        guard points.width > 0, let map = map(points, support: support) else { return input }

        for h in hands where (h.hasPose || h.holding) && h.speed < maxIntentSpeed && zone(of: h, map) == .nose {
            if h.pose2 { input.pose2Ready = true }
            if h.pose3 { input.pose3Ready = true }
            if h.holding { input.gripReady = true }
        }
        input.pointReady = leadZone(map, points) == .nose
        input.fingerNear = hands.contains { map.holds(.nose, at: $0.point) }
        return input
    }

    private func leadZone(_ map: FaceZoneMap, _ points: FacePoints) -> FaceZone? {
        guard ZoomTuning.fingerPointEnabled else { return nil }
        let inZones = hands
            .filter { $0.isPoint && $0.speed < maxIntentSpeed }
            .compactMap { h in map.zone(of: h.point, locked: locked).map { (point: h.point, zone: $0) } }
        if let locked, inZones.contains(where: { $0.zone == locked }) { return locked }
        guard let center = points.center else { return inZones.first?.zone }
        return inZones.min {
            hypot($0.point.x - center.x, $0.point.y - center.y) < hypot($1.point.x - center.x, $1.point.y - center.y)
        }?.zone
    }

    private func map(_ points: FacePoints, support: Bool) -> FaceZoneMap? {
        let reach = min(CGFloat(handProfile.enterDistance / ZoomTuning.handEnterDistance), ZoomTuning.maxTriggerScale)
        var lipsReach = CGFloat(handProfile.enterDistance)
        if support { lipsReach *= ZoomTuning.pitchLipsReach }
        return FaceZoneMap(points: points, reach: reach, lipsReach: lipsReach)
    }

    private func zone(of hand: TrackedHand, _ map: FaceZoneMap) -> FaceZone? {
        if let zone = map.zone(of: hand.point, locked: locked) { return zone }
        var counts: [FaceZone: Int] = [:]
        for p in hand.checkPoints {
            if let zone = map.zone(of: p, locked: locked) { counts[zone, default: 0] += 1 }
        }
        return FaceZone.allCases.reduce(FaceZone?.none) { best, zone in
            guard let count = counts[zone] else { return best }
            guard let best, let bestCount = counts[best] else { return zone }
            return count > bestCount ? zone : best
        }
    }
}
