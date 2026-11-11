import Foundation

nonisolated struct HeadPoseRecognizer {
    var defaultTurnEnter = 20.0
    var minTurnEnter = ZoomTuning.minTurnEnter
    var maxTurnEnter = 24.0
    var turnDwell: TimeInterval = ZoomTuning.sideEnterDwell
    var turnExitDwell: TimeInterval = ZoomTuning.sideExitDwell
    var yawTau = ZoomTuning.yawTau
    var maxYawRate = 60.0
    var yawSign = 1.0
    var lostGrace: TimeInterval = 0.8
    var coverGrace: TimeInterval = ZoomTuning.coverGrace
    var maxBaseline = 8.0
    var baselineTau = 6.0

    private(set) var profile: HeadProfile
    private(set) var current: ZoomTarget?

    private(set) var isStraight = false

    let turnAnchor: Double

    private(set) var quickReleased = false
    private var lastRawYaw: Double?
    private var travel = 0.0
    private var enteredAt: Date?

    private var pending: (target: ZoomTarget, since: Date)?
    private var exitPending: Date?
    private var smoothedYaw: Double?
    private var lastTime: Date?
    private var lastSeen: Date?
    private var episodeStart: Date?
    private var episodePeak = 0.0
    private var episodeSettled: TimeInterval = 0

    private var sawFace = false
    private var stepDt: TimeInterval = 0
    private var stepYawRate = 0.0

    init(profile: HeadProfile = HeadProfile(), turnAnchor: Double? = nil) {
        var p = profile
        p.yawBaseline = min(max(p.yawBaseline, -8), 8)
        if p.turnPeak != 0 { p.turnPeak = min(max(p.turnPeak, 20), 45) }
        self.profile = p
        self.turnAnchor = turnAnchor ?? (p.turnPeak > 0 ? p.turnPeak : ZoomTuning.turnPeakDefault)
    }

    private var enterAngle: Double {
        guard profile.turnPeak > 0 else { return defaultTurnEnter }
        return min(max(profile.turnPeak * 0.6, minTurnEnter), maxTurnEnter)
    }
    private var exitAngle: Double { enterAngle * 0.5 }
    private var relativeYaw: Double { (smoothedYaw ?? 0) - profile.yawBaseline }

    mutating func update(face: FaceObservation?, learn: Bool, covered: Bool = false,
                         yawFrozen: Bool = false, now: Date) -> ZoomTarget? {
        let before = current
        sawFace = false
        isStraight = false
        quickReleased = false
        let result = step(face: face, learn: learn, covered: covered, yawFrozen: yawFrozen, now: now)
        trackEpisode(before: before, now: now)
        return result
    }

    mutating func noteUnwantedSide() {
        let old = profile.turnPeak > 0 ? profile.turnPeak : ZoomTuning.turnPeakDefault
        let limit = min(turnAnchor + ZoomTuning.turnLearnSessionCap, 45)
        profile.turnPeak = max(old, min(old + ZoomTuning.turnUnwantedStep, limit))
    }

    private mutating func step(face: FaceObservation?, learn: Bool, covered: Bool,
                               yawFrozen: Bool, now: Date) -> ZoomTarget? {
        guard let face, face.yaw.isFinite else { return holdWhileLost(covered: covered, now: now) }
        lastSeen = now
        let dt = max(lastTime.map { now.timeIntervalSince($0) } ?? ZoomTuning.nominalStep, 0.001)
        lastTime = now

        let rawYaw = face.yaw * yawSign
        let rawDelta = abs(rawYaw - (lastRawYaw ?? rawYaw))
        lastRawYaw = rawYaw
        travel = travel * exp(-min(dt, ZoomTuning.maxStep) / ZoomTuning.sideFastExitTravelTau) + rawDelta
        let previousYaw = smoothedYaw ?? rawYaw
        let alpha = 1 - exp(-min(dt, ZoomTuning.maxStep) / yawTau)
        let smoothed = previousYaw + alpha * (rawYaw - previousYaw)
        smoothedYaw = smoothed
        let yawRate = abs(smoothed - previousYaw) / dt

        if yawFrozen {
            pending = nil
            return current
        }
        sawFace = true
        stepDt = dt
        stepYawRate = yawRate
        isStraight = abs(relativeYaw) < exitAngle

        if ZoomTuning.sideFastExitEnabled, current != nil, shouldFastExit(now: now) {
            current = nil
            pending = nil
            exitPending = nil
            enteredAt = nil
            travel = 0
            quickReleased = true
            return nil
        }

        if learn, current == nil, pending == nil,
           abs(relativeYaw) < exitAngle, yawRate < maxYawRate / 3 {
            let k = 1 - exp(-min(dt, ZoomTuning.maxStep) / baselineTau)
            let moved = profile.yawBaseline + (smoothed - profile.yawBaseline) * k
            profile.yawBaseline = min(max(moved, -maxBaseline), maxBaseline)
        }

        guard let raw = classify(relativeYaw) else {
            pending = nil
            guard current != nil else {
                exitPending = nil
                return nil
            }
            if exitPending == nil { exitPending = now }
            if let since = exitPending, now.timeIntervalSince(since) >= turnExitDwell {
                current = nil
                exitPending = nil
            }
            return current
        }
        exitPending = nil
        if raw == current {
            pending = nil
            return current
        }
        if yawRate > maxYawRate {
            pending = nil
            return current
        }
        if pending?.target != raw { pending = (raw, now) }
        if let p = pending, now.timeIntervalSince(p.since) >= turnDwell {
            current = raw
            pending = nil
            enteredAt = now
            travel = 0
        }
        return current
    }

    private func shouldFastExit(now: Date) -> Bool {
        guard let entered = enteredAt,
              now.timeIntervalSince(entered) >= ZoomTuning.sideFastExitArmDelay else { return false }
        return travel > ZoomTuning.sideFastExitTravel
    }

    private mutating func holdWhileLost(covered: Bool, now: Date) -> ZoomTarget? {
        let grace = covered ? max(lostGrace, coverGrace) : lostGrace
        if let seen = lastSeen, now.timeIntervalSince(seen) < grace {
            pending = nil
            return current
        }
        reset()
        return nil
    }

    private mutating func trackEpisode(before: ZoomTarget?, now: Date) {
        if current != nil {
            if before == nil {
                episodeStart = now
                episodePeak = 0
                episodeSettled = 0
            }
            if sawFace, stepYawRate < maxYawRate / 3, abs(relativeYaw) >= exitAngle {
                episodeSettled += min(stepDt, ZoomTuning.maxStep)
                episodePeak = max(episodePeak, abs(relativeYaw))
            }
        } else if before != nil, episodeStart != nil {
            episodeStart = nil
            guard episodeSettled >= ZoomTuning.turnLearnMinEpisode else { return }
            let old = profile.turnPeak > 0 ? profile.turnPeak : ZoomTuning.turnPeakDefault
            let peak = min(max(episodePeak, 20), 45)
            var moved = old + ZoomTuning.turnLearnStep * (peak - old)
            moved = min(max(moved, turnAnchor - ZoomTuning.turnLearnSessionCap),
                        turnAnchor + ZoomTuning.turnLearnSessionCap)
            profile.turnPeak = min(max(moved, 20), 45)
        }
    }

    private mutating func reset() {
        current = nil
        pending = nil
        exitPending = nil
        smoothedYaw = nil
        lastTime = nil
        lastSeen = nil
        episodeStart = nil
        enteredAt = nil
        lastRawYaw = nil
        travel = 0
    }

    private func classify(_ yaw: Double) -> ZoomTarget? {
        let limit = current == nil ? enterAngle : exitAngle
        guard abs(yaw) >= limit else { return nil }
        return .faceSide(yaw > 0 ? .left : .right)
    }
}
