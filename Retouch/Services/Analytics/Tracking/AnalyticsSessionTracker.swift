import Foundation

struct AnalyticsSample {
    var hasFace: Bool
    var target: ZoomTarget
    var zoomScale: Double
    var faceLux: Double?
    var isGlowAtMax: Bool
}

struct AnalyticsSessionTracker {
    private struct Session {
        var startedAt: Date
        var summary: AnalyticsSessionSummary
        var autoSeconds = 0.0
        var lockedSeconds = 0.0
        var zoomedSeconds = 0.0
        var bucketSeconds: [AnalyticsLightBucket: TimeInterval] = [:]
    }

    private struct ActiveZoom {
        var trigger: AnalyticsZoomTrigger
        var eyeSide: AnalyticsEyeSide?
        var since: Date
    }

    private struct PendingSettle {
        var from: AnalyticsZoomMode
        var to: AnalyticsZoomMode
        var secondsInPreviousMode: Int
        var secondsSinceLastAutoZoom: Int?
        var lastAutoTrigger: AnalyticsZoomTrigger?
        var positionsPassed: Int
        var targetScale: Double
        var since: Date
    }

    private let launchStartedAt: Date
    private var mode: AnalyticsZoomMode = .auto
    private var modeSince: Date?
    private var entry: AnalyticsSessionEntry = .coldLaunch
    private var session: Session?
    private var activeZoom: ActiveZoom?
    private var pendingSettle: PendingSettle?
    private var lastAutoTrigger: AnalyticsZoomTrigger?
    private var lastAutoZoomEnd: Date?
    private var awaitsAutoReset = false
    private var lastSample: AnalyticsSample?
    private var lastUpdate: Date?
    private var faceSeenSince: Date?
    private var lastFaceSeen: Date?
    private var bucket: AnalyticsLightBucket?
    private var isBackground = false
    private var interruptedAt: Date?
    private var hasReportedOpen = false
    private var sawPermissionPrompt = false

    init(launchStartedAt: Date) {
        self.launchStartedAt = launchStartedAt
        modeSince = launchStartedAt
    }

    mutating func update(_ sample: AnalyticsSample, at now: Date) -> [AnalyticsEvent] {
        accumulate(until: now)
        var events: [AnalyticsEvent] = []
        if let lux = sample.faceLux { bucket = Self.bucket(for: lux) }
        if sample.isGlowAtMax { session?.summary.glowMaxReached = true }
        updateFace(sample.hasFace, at: now, into: &events)
        updateZoom(sample, at: now, into: &events)
        updateSettle(sample, at: now, into: &events)
        lastSample = sample
        lastUpdate = now
        return events
    }

    mutating func partChanged(from old: FacePart, to new: FacePart, at now: Date) -> [AnalyticsEvent] {
        let next = AnalyticsZoomMode(part: new)
        guard next != mode else { return [] }
        var events = closeActiveZoom(at: now)
        events.append(contentsOf: flushSettle(at: now))
        pendingSettle = PendingSettle(
            from: mode,
            to: next,
            secondsInPreviousMode: Self.seconds(now.timeIntervalSince(modeSince ?? now)),
            secondsSinceLastAutoZoom: lastAutoZoomEnd.map { Self.seconds(now.timeIntervalSince($0)) },
            lastAutoTrigger: lastAutoTrigger,
            positionsPassed: Self.positions(from: old, to: new),
            targetScale: Double((new.zoomTarget ?? .fullFace).zoomScale),
            since: now)
        recordModeChange(to: next)
        mode = next
        modeSince = now
        awaitsAutoReset = next == .auto
        return events
    }

    mutating func bannerShown() {
        session?.summary.bannerShown += 1
    }

    mutating func cameraStateChanged(from old: CameraState, to new: CameraState, at now: Date) -> [AnalyticsEvent] {
        var events: [AnalyticsEvent] = []
        if old == .notDetermined, new != .notDetermined {
            sawPermissionPrompt = true
            events.append(.cameraPermissionResult(isGranted: new != .permissionDenied))
        }
        if new == .reconnecting, old == .running, !isBackground { interruptedAt = now }
        if new == .failed { interruptedAt = nil }
        guard new == .running else { return events }
        if let start = interruptedAt {
            interruptedAt = nil
            events.append(.cameraInterrupted(recoveryMs: Self.milliseconds(now.timeIntervalSince(start))))
        }
        if !hasReportedOpen {
            hasReportedOpen = true
            if !sawPermissionPrompt {
                events.append(.mirrorOpened(launchMs: Self.milliseconds(now.timeIntervalSince(launchStartedAt))))
            }
        }
        return events
    }

    mutating func appForegrounded() {
        isBackground = false
    }

    mutating func appBackgrounded(at now: Date) -> [AnalyticsEvent] {
        isBackground = true
        interruptedAt = nil
        var events = flushSettle(at: now)
        events.append(contentsOf: endSession(reason: .background, endedAt: now))
        lastSample = nil
        lastUpdate = nil
        lastFaceSeen = nil
        faceSeenSince = nil
        entry = .foreground
        return events
    }

    static func bucket(for lux: Double) -> AnalyticsLightBucket {
        if lux < AnalyticsConfig.darkLuxLimit { return .dark }
        if lux < AnalyticsConfig.dimLuxLimit { return .dim }
        if lux < AnalyticsConfig.enoughLuxLimit { return .enough }
        if lux < AnalyticsConfig.goodLuxLimit { return .good }
        return .veryBright
    }

    static func positions(from old: FacePart, to new: FacePart) -> Int {
        let all = FacePart.allCases
        guard let first = all.firstIndex(of: old), let second = all.firstIndex(of: new) else { return 0 }
        let distance = abs(first - second)
        return min(distance, all.count - distance)
    }

    private mutating func accumulate(until now: Date) {
        guard session != nil, let last = lastUpdate, let sample = lastSample, sample.hasFace else { return }
        let elapsed = max(0, now.timeIntervalSince(last))
        if mode == .auto { session?.autoSeconds += elapsed } else { session?.lockedSeconds += elapsed }
        if sample.target != .fullFace { session?.zoomedSeconds += elapsed }
        if let bucket { session?.bucketSeconds[bucket, default: 0] += elapsed }
    }

    private mutating func updateFace(_ hasFace: Bool, at now: Date, into events: inout [AnalyticsEvent]) {
        if hasFace {
            lastFaceSeen = now
            let since = faceSeenSince ?? now
            faceSeenSince = since
            if session == nil, now.timeIntervalSince(since) >= AnalyticsConfig.faceSeenToStartSession {
                events.append(startSession(at: now))
            }
            return
        }
        guard let last = lastFaceSeen else { return }
        let absence = now.timeIntervalSince(last)
        if absence >= AnalyticsConfig.faceLostGrace { faceSeenSince = nil }
        if session != nil, absence >= AnalyticsConfig.sessionEndTimeout {
            events.append(contentsOf: endSession(reason: .noFace, endedAt: last))
        }
    }

    private mutating func updateZoom(_ sample: AnalyticsSample, at now: Date, into events: inout [AnalyticsEvent]) {
        if awaitsAutoReset {
            guard sample.target == .fullFace else { return }
            awaitsAutoReset = false
        }
        let desired = mode == .auto ? Self.zoom(for: sample.target) : nil
        guard desired?.trigger != activeZoom?.trigger || desired?.eyeSide != activeZoom?.eyeSide else { return }
        events.append(contentsOf: closeActiveZoom(at: now))
        guard let desired else { return }
        activeZoom = ActiveZoom(trigger: desired.trigger, eyeSide: desired.eyeSide, since: now)
        lastAutoTrigger = desired.trigger
    }

    private mutating func updateSettle(_ sample: AnalyticsSample, at now: Date, into events: inout [AnalyticsEvent]) {
        guard let pending = pendingSettle else { return }
        let target = pending.targetScale
        let isSettled = target > 0 && abs(sample.zoomScale - target) / target <= AnalyticsConfig.settleTolerance
        let isTimedOut = now.timeIntervalSince(pending.since) >= AnalyticsConfig.settleTimeout
        guard isSettled || isTimedOut else { return }
        events.append(contentsOf: flushSettle(at: now))
    }

    private mutating func flushSettle(at now: Date) -> [AnalyticsEvent] {
        guard let pending = pendingSettle else { return [] }
        pendingSettle = nil
        return [.zoomModeChanged(from: pending.from,
                                 to: pending.to,
                                 secondsInPreviousMode: pending.secondsInPreviousMode,
                                 secondsSinceLastAutoZoom: pending.secondsSinceLastAutoZoom,
                                 lastAutoTrigger: pending.lastAutoTrigger,
                                 positionsPassed: pending.positionsPassed,
                                 settleMs: Self.milliseconds(now.timeIntervalSince(pending.since)))]
    }

    private mutating func closeActiveZoom(at now: Date) -> [AnalyticsEvent] {
        guard let active = activeZoom else { return [] }
        activeZoom = nil
        lastAutoZoomEnd = now
        let hold = max(0, now.timeIntervalSince(active.since))
        if session != nil { recordZoom(active.trigger, hold: hold) }
        return [.autoZoomTriggered(trigger: active.trigger,
                                   eyeSide: active.eyeSide,
                                   holdMs: Self.milliseconds(hold))]
    }

    private mutating func recordZoom(_ trigger: AnalyticsZoomTrigger, hold: TimeInterval) {
        switch trigger {
        case .eye: session?.summary.eyeZooms += 1
        case .lip: session?.summary.lipZooms += 1
        case .nose: session?.summary.noseZooms += 1
        case .headTurn: session?.summary.headTurnZooms += 1
        }
        if hold < AnalyticsConfig.likelyFalseZoomWindow { session?.summary.likelyFalseZooms += 1 }
    }

    private mutating func recordModeChange(to next: AnalyticsZoomMode) {
        session?.summary.modeChanges += 1
        switch next {
        case .auto: break
        case .lockRightEye: session?.summary.lockRightEyeUses += 1
        case .lockLeftEye: session?.summary.lockLeftEyeUses += 1
        case .lockMouth: session?.summary.lockMouthUses += 1
        case .lockNose: session?.summary.lockNoseUses += 1
        case .lockFullFace: session?.summary.lockFullFaceUses += 1
        }
    }

    private mutating func startSession(at now: Date) -> AnalyticsEvent {
        let calendar = Calendar.current
        let startBucket = bucket ?? .dark
        let summary = AnalyticsSessionSummary(startLocalHour: calendar.component(.hour, from: now),
                                              startWeekday: calendar.component(.weekday, from: now),
                                              lengthSeconds: 0,
                                              endReason: .background,
                                              lightBucket: startBucket,
                                              endedAt: now)
        session = Session(startedAt: now, summary: summary)
        let startEntry = entry
        entry = .foreground
        return .sessionStarted(entry: startEntry, lightBucket: startBucket)
    }

    private mutating func endSession(reason: AnalyticsSessionEndReason, endedAt: Date) -> [AnalyticsEvent] {
        var events = closeActiveZoom(at: endedAt)
        guard var finished = session else { return events }
        finished.summary.lengthSeconds = Self.seconds(endedAt.timeIntervalSince(finished.startedAt))
        finished.summary.endReason = reason
        finished.summary.endedAt = endedAt
        finished.summary.zoomedTimeSeconds = Self.seconds(finished.zoomedSeconds)
        finished.summary.timeInAutoSeconds = Self.seconds(finished.autoSeconds)
        finished.summary.timeLockedSeconds = Self.seconds(finished.lockedSeconds)
        finished.summary.lightBucket = finished.bucketSeconds.max { $0.value < $1.value }?.key
            ?? finished.summary.lightBucket
        finished.summary.modeAtEnd = mode
        session = nil
        faceSeenSince = nil
        events.append(.sessionEnded(finished.summary))
        return events
    }

    private static func zoom(for target: ZoomTarget) -> (trigger: AnalyticsZoomTrigger, eyeSide: AnalyticsEyeSide?)? {
        switch target {
        case .fullFace, .overall: return nil
        case .leftEye: return (.eye, .left)
        case .rightEye: return (.eye, .right)
        case .lips: return (.lip, nil)
        case .nose: return (.nose, nil)
        case .faceSide, .cheek: return (.headTurn, nil)
        }
    }

    private static func seconds(_ interval: TimeInterval) -> Int {
        Int(max(0, interval).rounded())
    }

    private static func milliseconds(_ interval: TimeInterval) -> Int {
        Int((max(0, interval) * AnalyticsConfig.millisecondsPerSecond).rounded())
    }
}
