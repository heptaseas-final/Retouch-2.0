import CoreGraphics

nonisolated struct ZoomReadiness {
    let hands: [TrackedHand]
    let scan: HandScan
    let converter: CoordinateConverter
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

    static func applying(_ tools: ToolZoneReading, to input: CheekZoomFlow.Input) -> CheekZoomFlow.Input {
        var result = input
        result.readyLeft = input.readyLeft || tools.cheekTriggerLeft
        result.readyRight = input.readyRight || tools.cheekTriggerRight
        result.nearLeft = input.nearLeft || tools.cheekHoldLeft
        result.nearRight = input.nearRight || tools.cheekHoldRight
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
        guard points.width > 0, let map = FaceZoneMap(points: points) else { return input }
        if support { input.enterDwellFactor = ZoomTuning.pitchEyeDwellFactor }

        for h in hands where (h.hasPose || h.holding) && h.speed < maxIntentSpeed {
            switch zone(of: h, map, points) {
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
        for p in touchPoints {
            if map.holds(.leftEye, at: p) { input.holdLeft = true }
            if map.holds(.rightEye, at: p) { input.holdRight = true }
        }
        return input
    }

    func lips(points: FacePoints) -> LipsZoomFlow.Input {
        var input = LipsZoomFlow.Input()
        input.handLost = scan.handsSeen == 0 && hands.isEmpty
        input.handMovingAway = hands.contains { $0.speed >= maxIntentSpeed }
        guard points.width > 0, let map = FaceZoneMap(points: points) else { return input }

        for h in hands where (h.hasPose || h.holding) && h.speed < maxIntentSpeed && zone(of: h, map, points) == .lips {
            if h.pose2 { input.pose2Ready = true }
            if h.pose3 { input.pose3Ready = true }
            if h.holding { input.gripReady = true }
        }
        input.pointReady = leadZone(map, points) == .lips
        input.fingerNear = touchPoints.contains { map.holds(.lips, at: $0) }
        return input
    }

    func nose(points: FacePoints) -> NoseZoomFlow.Input {
        var input = NoseZoomFlow.Input()
        input.handLost = scan.handsSeen == 0 && hands.isEmpty
        input.handMovingAway = hands.contains { $0.speed >= maxIntentSpeed }
        guard points.width > 0, let map = FaceZoneMap(points: points) else { return input }

        for h in hands where (h.hasPose || h.holding) && h.speed < maxIntentSpeed && zone(of: h, map, points) == .nose {
            if h.pose2 { input.pose2Ready = true }
            if h.pose3 { input.pose3Ready = true }
            if h.holding { input.gripReady = true }
        }
        input.pointReady = leadZone(map, points) == .nose
        input.fingerNear = touchPoints.contains { map.holds(.nose, at: $0) }
        return input
    }

    func cheek(points: FacePoints) -> CheekZoomFlow.Input {
        var input = CheekZoomFlow.Input()
        input.handMovingAway = hands.contains { $0.speed >= maxIntentSpeed }
        guard points.width > 0, let map = FaceZoneMap(points: points) else { return input }

        for h in hands where (h.hasPose || h.holding) && h.speed < maxIntentSpeed {
            switch zone(of: h, map, points) {
            case .leftCheek: input.readyLeft = true
            case .rightCheek: input.readyRight = true
            default: break
            }
        }
        switch leadZone(map, points) {
        case .leftCheek: input.readyLeft = true
        case .rightCheek: input.readyRight = true
        default: break
        }
        input.nearLeft = touchPoints.contains { map.holds(.leftCheek, at: $0) }
        input.nearRight = touchPoints.contains { map.holds(.rightCheek, at: $0) }
        return input
    }

    private func leadZone(_ map: FaceZoneMap, _ points: FacePoints) -> FaceZone? {
        guard ZoomTuning.fingerPointEnabled else { return nil }
        let inZones = hands
            .filter { $0.isPoint && $0.speed < maxIntentSpeed }
            .compactMap { h in zone(of: h, map, points).map { (point: h.point, zone: $0) } }
        if let locked, inZones.contains(where: { $0.zone == locked }) { return locked }
        guard let center = points.center else { return inZones.first?.zone }
        return inZones.min {
            hypot($0.point.x - center.x, $0.point.y - center.y) < hypot($1.point.x - center.x, $1.point.y - center.y)
        }?.zone
    }

    private var fingertips: [CGPoint] {
        guard ZoomTuning.fingertipVoteEnabled else { return [] }
        return scan.fingertips.map { converter.toView($0) }
    }

    private var touchPoints: [CGPoint] {
        hands.map(\.point) + fingertips
    }

    private func zone(of hand: TrackedHand, _ map: FaceZoneMap, _ points: FacePoints) -> FaceZone? {
        let reach = points.width * ZoomTuning.fingertipVoteRadius
        let nearTips = fingertips.filter { hypot($0.x - hand.point.x, $0.y - hand.point.y) <= reach }
        return map.zone(primary: hand.point, others: hand.checkPoints + nearTips, locked: locked)
    }
}
