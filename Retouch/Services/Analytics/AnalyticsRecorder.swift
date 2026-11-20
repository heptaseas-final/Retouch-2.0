import Foundation

protocol OnboardingAnalyticsRecording: AnyObject {
    func onboardingStepCompleted(step: String)
    func onboardingSkipped(step: String)
    func onboardingCompleted()
}

protocol AnalyticsRecording: OnboardingAnalyticsRecording {
    func appDidBecomeActive()
    func appDidEnterBackground()
    func cameraStateChanged(from old: CameraState, to new: CameraState)
    func partChanged(from old: FacePart, to new: FacePart)
    func lightModeChanged(to mode: LightMode)
    func pinchEnded(scale: Double)
    func statusChanged(to status: MirrorStatus?, faceLux: Double?)
    func replayTutorialOpened()
    func shortcutPromptShown()
    func shortcutGuideOpened(fromPrompt: Bool)
    func shortcutPromptDismissedForever()
    var isAnalyticsEnabled: Bool { get }
    func setAnalyticsEnabled(_ isEnabled: Bool)
}

final class AnalyticsRecorder: AnalyticsRecording {
    private let service: AnalyticsServicing
    private let zoomStore: ZoomStore
    private let lighting: LightingServicing
    private var tracker: AnalyticsSessionTracker
    private var autoLightTracker = AutoLightTracker()
    private var lightMode: LightMode = .off
    private var isActive = false
    private var pollTask: Task<Void, Never>?
    private var listener: UUID?
    private var thermalState = ProcessInfo.processInfo.thermalState
    private var isHeatLimited = false

    init(service: AnalyticsServicing, zoomStore: ZoomStore, lighting: LightingServicing, launchStartedAt: Date = Date()) {
        self.service = service
        self.zoomStore = zoomStore
        self.lighting = lighting
        tracker = AnalyticsSessionTracker(launchStartedAt: launchStartedAt)
        listener = zoomStore.addTrackingListener { [weak self] _, _ in self?.ingest() }
    }

    func appDidBecomeActive() {
        isActive = true
        tracker.appForegrounded()
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.pollEnvironment()
                try? await Task.sleep(for: AnalyticsConfig.pollInterval)
            }
        }
    }

    func appDidEnterBackground() {
        isActive = false
        pollTask?.cancel()
        pollTask = nil
        send(tracker.appBackgrounded(at: Date()))
        autoLightTracker.reset()
    }

    func cameraStateChanged(from old: CameraState, to new: CameraState) {
        send(tracker.cameraStateChanged(from: old, to: new, at: Date()))
    }

    func partChanged(from old: FacePart, to new: FacePart) {
        send(tracker.partChanged(from: old, to: new, at: Date()))
    }

    func lightModeChanged(to mode: LightMode) {
        guard mode != lightMode else { return }
        let wasOn = lightMode.isOn
        lightMode = mode
        if let color = mode.lightColor {
            service.track(.lightChanged(color: AnalyticsLightColor(color)))
        } else if wasOn {
            service.track(.autoLightResumed)
        }
    }

    func pinchEnded(scale: Double) {
        service.track(.pinchZoomUsed(zoomLevel: scale))
    }

    func onboardingStepCompleted(step: String) {
        service.track(.onboardingStepCompleted(step: step))
    }

    func onboardingSkipped(step: String) {
        service.track(.onboardingSkipped(step: step))
    }

    func onboardingCompleted() {
        service.track(.onboardingCompleted)
    }

    func replayTutorialOpened() {
        service.track(.replayTutorialOpened)
    }

    func shortcutPromptShown() {
        service.track(.shortcutPromptShown)
    }

    func shortcutGuideOpened(fromPrompt: Bool) {
        service.track(.shortcutGuideOpened(source: fromPrompt ? .prompt : .settings))
    }

    func shortcutPromptDismissedForever() {
        service.track(.shortcutPromptDismissedForever)
    }

    var isAnalyticsEnabled: Bool { service.isEnabled }

    func setAnalyticsEnabled(_ isEnabled: Bool) {
        service.setEnabled(isEnabled)
    }

    func statusChanged(to status: MirrorStatus?, faceLux: Double?) {
        guard let status else { return }
        tracker.bannerShown()
        switch status {
        case .notEnoughLight: service.track(.dimBannerShown(faceLux: Self.roundedLux(faceLux)))
        case .enoughLight: service.track(.lightGoodShown(faceLux: Self.roundedLux(faceLux)))
        default: break
        }
    }

    private func ingest() {
        guard isActive else { return }
        let status = lighting.status
        let sample = AnalyticsSample(hasFace: status.faceLux != nil,
                                     target: zoomStore.tracking.target,
                                     zoomScale: Double(zoomStore.zoomState.scale),
                                     faceLux: status.faceLux,
                                     isGlowAtMax: status.isGlowAtMax)
        let now = Date()
        send(tracker.update(sample, at: now))
        let light = AutoLightSample(faceLux: status.faceLux,
                                    glowLevel: lighting.ringLightLevel,
                                    isAuto: lighting.isAutoBrightness,
                                    isGlowAtMax: status.isGlowAtMax)
        send(autoLightTracker.update(light, at: now))
    }

    private func pollEnvironment() {
        ingest()
        let thermal = ProcessInfo.processInfo.thermalState
        if thermal != thermalState {
            thermalState = thermal
            service.track(.thermalStateChanged(state: AnalyticsThermalState(thermal)))
        }
        let isLimited = lighting.status.isHeatLimited
        if isLimited, !isHeatLimited { service.track(.glowLimitedByHeat) }
        isHeatLimited = isLimited
    }

    private func send(_ events: [AnalyticsEvent]) {
        for event in events { service.track(event) }
    }

    private static func roundedLux(_ lux: Double?) -> Int {
        guard let lux, lux.isFinite else { return 0 }
        return Int(lux.rounded())
    }
}

private extension AnalyticsLightColor {
    init(_ color: LightColor) {
        switch color {
        case .white: self = .white
        case .warm: self = .warm
        case .cool: self = .cool
        }
    }
}

private extension AnalyticsThermalState {
    init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .nominal
        }
    }
}
