import Foundation

nonisolated struct LipsZoomFlow {
    enum Phase: Equatable { case idle, entering, active, releasing }
    enum Trigger: Equatable { case twoFinger, threeFinger, grip, point, tool }

    struct Input {
        var pose2Ready = false
        var pose3Ready = false
        var gripReady = false
        var pointReady = false
        var toolReady = false
        var fingerNear = false
        var lipsMoving = false
        var handLost = false
    }

    var enterDwell = ZoomTuning.lipsEnterDwell
    var gripDwell = ZoomTuning.eyeLipsGripDwell
    var pointDwell = ZoomTuning.fingerPointDwell
    var toolDwell = ZoomTuning.toolEnterDwell
    var releaseDwell = ZoomTuning.lipsReleaseDwell
    var poseGrace = ZoomTuning.eyeFlowPoseGrace

    private(set) var phase: Phase = .idle
    private(set) var trigger: Trigger?
    private var pose2Since: Date?
    private var pose3Since: Date?
    private var gripSince: Date?
    private var pose2Seen: Date?
    private var pose3Seen: Date?
    private var gripSeen: Date?
    private var pointSince: Date?
    private var pointSeen: Date?
    private var toolSince: Date?
    private var toolSeen: Date?
    private var releaseSince: Date?
    private var lostSince: Date?

    var isActive: Bool { phase == .active || phase == .releasing }

    func releaseRemaining(now: Date) -> TimeInterval? {
        guard phase == .releasing, let since = releaseSince else { return nil }
        return max(releaseDwell - now.timeIntervalSince(since), 0)
    }

    private static func track(_ present: Bool, since: Date?, seen: inout Date?,
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
    mutating func update(_ input: Input, now: Date) -> Bool {
        switch phase {
        case .idle, .entering:
            releaseSince = nil
            lostSince = nil
            pose2Since = Self.track(input.pose2Ready, since: pose2Since, seen: &pose2Seen, now: now, grace: poseGrace)
            pose3Since = Self.track(input.pose3Ready, since: pose3Since, seen: &pose3Seen, now: now, grace: poseGrace)
            gripSince = Self.track(input.gripReady, since: gripSince, seen: &gripSeen, now: now, grace: poseGrace)
            pointSince = Self.track(input.pointReady, since: pointSince, seen: &pointSeen, now: now, grace: poseGrace)
            toolSince = Self.track(input.toolReady, since: toolSince, seen: &toolSeen, now: now, grace: poseGrace)

            var due: [(Trigger, Date)] = []
            if let s = pose2Since, now.timeIntervalSince(s) >= enterDwell { due.append((.twoFinger, s)) }
            if let s = pose3Since, now.timeIntervalSince(s) >= enterDwell { due.append((.threeFinger, s)) }
            if let s = gripSince, now.timeIntervalSince(s) >= gripDwell { due.append((.grip, s)) }
            if let s = pointSince, now.timeIntervalSince(s) >= pointDwell { due.append((.point, s)) }
            if let s = toolSince, now.timeIntervalSince(s) >= toolDwell { due.append((.tool, s)) }
            if let first = due.min(by: { $0.1 < $1.1 }) {
                trigger = first.0
                clearEntryTimers()
                phase = .active
            } else {
                phase = (pose2Since != nil || pose3Since != nil || gripSince != nil || pointSince != nil
                         || toolSince != nil) ? .entering : .idle
            }

        case .active, .releasing:
            clearEntryTimers()

            let lostOK: Bool
            if input.handLost && !input.fingerNear && !input.lipsMoving {
                if lostSince == nil { lostSince = now }
                lostOK = now.timeIntervalSince(lostSince!) < ZoomTuning.handLostHoldCap
            } else {
                lostSince = nil
                lostOK = false
            }

            if input.fingerNear || input.lipsMoving || lostOK {
                releaseSince = nil
                phase = .active
            } else {
                if releaseSince == nil { releaseSince = now }
                phase = .releasing
                if let since = releaseSince, now.timeIntervalSince(since) >= releaseDwell {
                    goIdle()
                }
            }
        }
        return isActive
    }

    mutating func cancel() { goIdle() }

    private mutating func clearEntryTimers() {
        pose2Since = nil
        pose3Since = nil
        gripSince = nil
        pointSince = nil
        toolSince = nil
        toolSeen = nil
        pose2Seen = nil
        pose3Seen = nil
        gripSeen = nil
        pointSeen = nil
    }

    private mutating func goIdle() {
        phase = .idle
        trigger = nil
        clearEntryTimers()
        releaseSince = nil
        lostSince = nil
    }
}
