import Foundation

nonisolated struct EyeZoomFlow {
    enum Phase: Equatable { case idle, entering, active, releasing }

    struct Input {
        var poseLeft = false
        var poseRight = false
        var holdLeft = false
        var holdRight = false
        var gripLeft = false
        var gripRight = false
        var pointLeft = false
        var pointRight = false
        var toolLeft = false
        var toolRight = false
        var activityLeft: EyeActivity = .idle
        var activityRight: EyeActivity = .idle
        var toolHoldLeft = false
        var toolHoldRight = false
        var enterDwellFactor: TimeInterval = 1
        var enterFloor: TimeInterval = 0
        var handLost = false
        var handMovingAway = false
    }

    var enterDwell = ZoomTuning.eyeFlowEnterDwell
    var gripDwell = ZoomTuning.eyeLipsGripDwell
    var pointDwell = ZoomTuning.fingerPointDwell
    var toolDwell = ZoomTuning.toolEnterDwell
    var switchDwell = ZoomTuning.eyeFlowSwitchDwell
    var toolSwitchDwell = ZoomTuning.toolSwitchDwell
    var releaseDwell = ZoomTuning.eyeFlowReleaseDwell
    var fastReleaseDwell = ZoomTuning.fastReleaseDwell
    var poseGrace = ZoomTuning.eyeFlowPoseGrace
    var softHoldWindow = ZoomTuning.softHoldWindow
    var holdGrace = ZoomTuning.holdGrace
    var reentryWindow = ZoomTuning.reentryWindow
    var reentryDwell = ZoomTuning.reentryDwell

    private(set) var phase: Phase = .idle
    private(set) var side: EyeSide?
    private(set) var holdReason = "-"
    private var leftSince: Date?
    private var rightSince: Date?
    private var leftSeen: Date?
    private var rightSeen: Date?
    private var gripLeftSince: Date?
    private var gripRightSince: Date?
    private var gripLeftSeen: Date?
    private var gripRightSeen: Date?
    private var pointLeftSince: Date?
    private var pointRightSince: Date?
    private var pointLeftSeen: Date?
    private var pointRightSeen: Date?
    private var toolLeftSince: Date?
    private var toolRightSince: Date?
    private var toolLeftSeen: Date?
    private var toolRightSeen: Date?
    private var switchPending: (side: EyeSide, since: Date)?
    private var releaseSince: Date?
    private var lastHeld: Date?
    private var lostSince: Date?
    private var lastExit: (side: EyeSide, at: Date)?

    var isActive: Bool { phase == .active || phase == .releasing }

    var target: ZoomTarget? {
        guard isActive, let side else { return nil }
        return side == .left ? .leftEye : .rightEye
    }

    func releaseRemaining(now: Date) -> TimeInterval? {
        guard phase == .releasing, let since = releaseSince else { return nil }
        return max(releaseDwell - now.timeIntervalSince(since), 0)
    }

    private static func trackPose(_ present: Bool, since: Date?, seen: inout Date?,
                                  now: Date, grace: TimeInterval) -> Date? {
        if present {
            seen = now
            return since ?? now
        }
        if let last = seen, let since, now.timeIntervalSince(last) <= grace { return since }
        seen = nil
        return nil
    }

    @discardableResult
    mutating func update(_ input: Input, now: Date) -> ZoomTarget? {
        switch phase {
        case .idle, .entering:
            holdReason = "-"
            leftSince = Self.trackPose(input.poseLeft, since: leftSince, seen: &leftSeen,
                                       now: now, grace: poseGrace)
            rightSince = Self.trackPose(input.poseRight, since: rightSince, seen: &rightSeen,
                                        now: now, grace: poseGrace)
            gripLeftSince = Self.trackPose(input.gripLeft, since: gripLeftSince, seen: &gripLeftSeen,
                                           now: now, grace: poseGrace)
            gripRightSince = Self.trackPose(input.gripRight, since: gripRightSince, seen: &gripRightSeen,
                                            now: now, grace: poseGrace)
            pointLeftSince = Self.trackPose(input.pointLeft, since: pointLeftSince, seen: &pointLeftSeen,
                                            now: now, grace: poseGrace)
            pointRightSince = Self.trackPose(input.pointRight, since: pointRightSince, seen: &pointRightSeen,
                                             now: now, grace: poseGrace)
            toolLeftSince = Self.trackPose(input.toolLeft, since: toolLeftSince, seen: &toolLeftSeen,
                                           now: now, grace: poseGrace)
            toolRightSince = Self.trackPose(input.toolRight, since: toolRightSince, seen: &toolRightSeen,
                                            now: now, grace: poseGrace)
            let need = enterDwell * input.enterDwellFactor
            let pointNeed = pointDwell * input.enterDwellFactor
            let gripNeed = gripDwell * input.enterDwellFactor
            func due(_ since: Date?, _ need: TimeInterval, _ side: EyeSide) -> Date? {
                let required = max(dwell(need, for: side, now: now), input.enterFloor)
                guard let s = since, now.timeIntervalSince(s) >= required else { return nil }
                return s
            }
            let dueL = [due(leftSince, need, .left), due(gripLeftSince, gripNeed, .left),
                        due(pointLeftSince, pointNeed, .left), due(toolLeftSince, toolDwell, .left)]
                .compactMap { $0 }.min()
            let dueR = [due(rightSince, need, .right), due(gripRightSince, gripNeed, .right),
                        due(pointRightSince, pointNeed, .right), due(toolRightSince, toolDwell, .right)]
                .compactMap { $0 }.min()
            if dueL != nil || dueR != nil {
                if let l = dueL, let r = dueR {
                    side = l <= r ? .left : .right
                } else {
                    side = dueL != nil ? .left : .right
                }
                begin(at: now)
            } else {
                phase = (leftSince != nil || rightSince != nil || gripLeftSince != nil || gripRightSince != nil
                         || pointLeftSince != nil || pointRightSince != nil
                         || toolLeftSince != nil || toolRightSince != nil)
                    ? .entering : .idle
            }

        case .active, .releasing:
            guard let current = side else {
                goIdle()
                break
            }
            clearTimers()
            let other: EyeSide = current == .left ? .right : .left
            let poseHere = current == .left ? input.poseLeft : input.poseRight
            let poseThere = other == .left ? input.poseLeft : input.poseRight
            let gripHere = current == .left ? input.gripLeft : input.gripRight
            let gripThere = other == .left ? input.gripLeft : input.gripRight
            let pointHere = current == .left ? input.pointLeft : input.pointRight
            let pointThere = other == .left ? input.pointLeft : input.pointRight

            let toolHere = current == .left ? input.toolLeft : input.toolRight
            let toolThere = other == .left ? input.toolLeft : input.toolRight
            let toolHoldHere = current == .left ? input.toolHoldLeft : input.toolHoldRight
            let toolSwitches = toolThere && !toolHoldHere

            if (poseThere || gripThere || pointThere || toolSwitches) && !(poseHere || gripHere || pointHere || toolHere) {
                if switchPending?.side != other { switchPending = (other, now) }
                let switchNeed = toolSwitches && !(poseThere || gripThere || pointThere) ? toolSwitchDwell : switchDwell
                if let p = switchPending, now.timeIntervalSince(p.since) >= switchNeed {
                    side = other
                    switchPending = nil
                    releaseSince = nil
                    lastHeld = now
                    phase = .active
                    return target
                }
            } else {
                switchPending = nil
            }

            let handHold = current == .left ? input.holdLeft : input.holdRight
            let activity = current == .left ? input.activityLeft : input.activityRight

            if handHold { lastHeld = now }
            let recentlyHeld = lastHeld.map { now.timeIntervalSince($0) <= softHoldWindow } ?? false
            let soft = activity == .active || activity == .turning
            let graceOK = lastHeld.map { now.timeIntervalSince($0) <= holdGrace } ?? false
            let softOK = soft && recentlyHeld
            let unknownOK = activity == .unknown && recentlyHeld

            let lostOK: Bool
            if input.handLost && !handHold {
                if lostSince == nil { lostSince = now }
                lostOK = now.timeIntervalSince(lostSince!) < ZoomTuning.handLostHoldCap
            } else {
                lostSince = nil
                lostOK = false
            }

            let switching = switchPending != nil
            let holding = handHold || graceOK || softOK || unknownOK || lostOK || switching
            if handHold {
                holdReason = "jari"
            } else if switching {
                holdReason = "pindah"
            } else if softOK {
                holdReason = activity == .turning ? "menoleh" : "mata aktif"
            } else if unknownOK {
                holdReason = "data hilang"
            } else if lostOK {
                holdReason = "tangan hilang"
            } else if graceOK {
                holdReason = "jeda"
            } else {
                holdReason = "-"
            }

            if holding {
                releaseSince = nil
                phase = .active
            } else {
                if releaseSince == nil { releaseSince = now }
                phase = .releasing
                let releaseNeed = input.handMovingAway ? min(fastReleaseDwell, releaseDwell) : releaseDwell
                if let since = releaseSince, now.timeIntervalSince(since) >= releaseNeed {
                    lastExit = (current, now)
                    goIdle()
                }
            }
        }
        return target
    }

    mutating func cancel() { goIdle() }

    private mutating func clearTimers() {
        leftSince = nil
        rightSince = nil
        leftSeen = nil
        rightSeen = nil
        gripLeftSince = nil
        gripRightSince = nil
        gripLeftSeen = nil
        gripRightSeen = nil
        pointLeftSince = nil
        pointRightSince = nil
        pointLeftSeen = nil
        pointRightSeen = nil
        toolLeftSince = nil
        toolRightSince = nil
        toolLeftSeen = nil
        toolRightSeen = nil
    }

    private func dwell(_ need: TimeInterval, for side: EyeSide, now: Date) -> TimeInterval {
        guard let exit = lastExit, exit.side == side,
              now.timeIntervalSince(exit.at) <= reentryWindow else { return need }
        return min(need, reentryDwell)
    }

    private mutating func begin(at now: Date) {
        phase = .active
        clearTimers()
        switchPending = nil
        releaseSince = nil
        lastHeld = now
        lostSince = nil
    }

    private mutating func goIdle() {
        phase = .idle
        side = nil
        holdReason = "-"
        clearTimers()
        switchPending = nil
        releaseSince = nil
        lastHeld = nil
        lostSince = nil
    }
}
