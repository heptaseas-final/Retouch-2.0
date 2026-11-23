import Foundation
import UIKit

protocol OnboardingAnalyticsRecording: AnyObject {
    func onboardingStarted()
    func onboardingStepCompleted(step: String, index: Int)
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
    private let installTracker: InstallTracker
    private var tracker: AnalyticsSessionTracker
    private var autoLightTracker = AutoLightTracker()
    private var performanceTracker = PerformanceHealthTracker()
    private var onboardingStartedAt: Date?
    private var onboardingSteps = 0
    private var replayCount = 0
    private var hasOpenedReplay = false
    private var lightMode: LightMode = .off
    private var isActive = false
    private var pollTask: Task<Void, Never>?
    private var listener: UUID?
    private var thermalState = ProcessInfo.processInfo.thermalState
    private var isHeatLimited = false

    init(service: AnalyticsServicing, zoomStore: ZoomStore, lighting: LightingServicing,
         installTracker: InstallTracker = InstallTracker(), launchStartedAt: Date = Date()) {
        self.service = service
        self.zoomStore = zoomStore
        self.lighting = lighting
        self.installTracker = installTracker
        UIDevice.current.isBatteryMonitoringEnabled = true
        tracker = AnalyticsSessionTracker(launchStartedAt: launchStartedAt)
        listener = zoomStore.addTrackingListener { [weak self] _, _ in self?.ingest() }
    }

    func appDidBecomeActive() {
        isActive = true
        tracker.appForegrounded()
        send(installTracker.launched(at: Date()))
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
        let now = Date()
        send(tracker.appBackgrounded(at: now))
        send(installTracker.appBackgrounded(at: now))
        autoLightTracker.reset()
        performanceTracker.reset()
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
        tracker.pinchUsed()
        service.track(.pinchZoomUsed(zoomLevel: scale))
    }

    func onboardingStarted() {
        onboardingStartedAt = Date()
        onboardingSteps = 0
        service.track(.onboardingStarted(variant: AnalyticsConfig.onboardingVariant,
                                         entry: hasOpenedReplay ? .settings : .firstLaunch))
    }

    func onboardingStepCompleted(step: String, index: Int) {
        onboardingSteps += 1
        service.track(.onboardingStepCompleted(step: step, stepIndex: index,
                                               secondsSinceStart: secondsSinceOnboardingStart()))
    }

    func onboardingSkipped(step: String) {
        service.track(.onboardingSkipped(step: step))
    }

    func onboardingCompleted() {
        service.track(.onboardingCompleted(completionTimeSeconds: secondsSinceOnboardingStart(),
                                           completedStepCount: onboardingSteps))
        onboardingStartedAt = nil
    }

    func replayTutorialOpened() {
        hasOpenedReplay = true
        replayCount += 1
        service.track(.replayTutorialOpened(replayCount: replayCount,
                                            sessionLengthSeconds: tracker.sessionLength(at: Date())))
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
                                     isGlowAtMax: status.isGlowAtMax,
                                     isNightModeEnabled: lighting.config.nightModeEnabled)
        let now = Date()
        let events = tracker.update(sample, at: now)
        send(events)
        if events.contains(where: { if case .sessionStarted = $0 { return true } else { return false } }) {
            send(installTracker.mirrorSessionStarted(at: now))
        }
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
        send(performanceTracker.update(PerformanceHealthSample(
            thermalState: AnalyticsThermalState(thermal),
            batteryLevel: Self.batteryLevel(),
            sessionLengthSeconds: tracker.sessionLength(at: Date()))))
    }

    private func secondsSinceOnboardingStart() -> Int {
        guard let start = onboardingStartedAt else { return 0 }
        return AnalyticsSessionMetrics.seconds(Date().timeIntervalSince(start))
    }

    private static func batteryLevel() -> Double? {
        let level = UIDevice.current.batteryLevel
        return level < 0 ? nil : Double(level)
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
