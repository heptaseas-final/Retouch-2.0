
import Foundation

nonisolated struct CheekZoomFlow {
    enum Phase: Equatable { case idle, entering, active, releasing }

    struct Input {
        var readyLeft = false
        var readyRight = false
        var nearLeft = false
        var nearRight = false
        var handMovingAway = false
        var enterFloor: TimeInterval = 0
    }

    var enterDwell = ZoomTuning.cheekEnterDwell
    var releaseDwell = ZoomTuning.cheekReleaseDwell
    var fastReleaseDwell = ZoomTuning.fastReleaseDwell
    var holdGrace = ZoomTuning.holdGrace
    var poseGrace = ZoomTuning.eyeFlowPoseGrace

    private(set) var phase: Phase = .idle
    private(set) var side: FaceSide?
    private var leftSince: Date?
    private var rightSince: Date?
    private var leftSeen: Date?
    private var rightSeen: Date?
    private var releaseSince: Date?
    private var lastNear: Date?

    var isActive: Bool { phase == .active || phase == .releasing }

    var target: ZoomTarget? {
        guard isActive, let side else { return nil }
        return .cheek(side)
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
            leftSince = Self.track(input.readyLeft, since: leftSince, seen: &leftSeen, now: now, grace: poseGrace)
            rightSince = Self.track(input.readyRight, since: rightSince, seen: &rightSeen, now: now, grace: poseGrace)
            let need = max(enterDwell, input.enterFloor)
            let dueLeft = leftSince.flatMap { now.timeIntervalSince($0) >= need ? $0 : nil }
            let dueRight = rightSince.flatMap { now.timeIntervalSince($0) >= need ? $0 : nil }
            if dueLeft != nil || dueRight != nil {
                if let left = dueLeft, let right = dueRight {
                    side = left <= right ? .left : .right
                } else {
                    side = dueLeft != nil ? .left : .right
                }
                clearEntryTimers()
                lastNear = now
                phase = .active
            } else {
                phase = (leftSince != nil || rightSince != nil) ? .entering : .idle
            }

        case .active, .releasing:
            clearEntryTimers()
            let near = side == .left ? input.nearLeft : input.nearRight
            if near { lastNear = now }
            let graceOK = lastNear.map { now.timeIntervalSince($0) <= holdGrace } ?? false
            if near || graceOK {
                releaseSince = nil
                phase = .active
            } else {
                if releaseSince == nil { releaseSince = now }
                phase = .releasing
                let releaseNeed = input.handMovingAway ? min(fastReleaseDwell, releaseDwell) : releaseDwell
                if let since = releaseSince, now.timeIntervalSince(since) >= releaseNeed { goIdle() }
            }
        }
        return isActive
    }

    mutating func cancel() { goIdle() }

    private mutating func clearEntryTimers() {
        leftSince = nil
        rightSince = nil
        leftSeen = nil
        rightSeen = nil
    }

    private mutating func goIdle() {
        phase = .idle
        side = nil
        clearEntryTimers()
        releaseSince = nil
        lastNear = nil
    }
}
