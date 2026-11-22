import CoreGraphics
import Foundation
import Observation

@Observable
final class MirrorViewModel {
    private(set) var selectedPart: FacePart = .face
    private(set) var lightMode: LightMode = .off
    private(set) var isLargerButtons: Bool
    private(set) var lightPlacement: LightPlacement
    private(set) var isAnalyticsEnabled: Bool
    private(set) var status: MirrorStatus?
    private(set) var isShortcutPromptVisible = false
    private(set) var isShortcutGuideVisible = false
    private(set) var isOverallOn = false
    private(set) var shownGlowLevel = 0.0

    @ObservationIgnored let renderer: MirrorRenderer
    @ObservationIgnored private let camera: CameraServicing
    @ObservationIgnored private let lighting: LightingServicing
    @ObservationIgnored private let zoom: ZoomServicing
    @ObservationIgnored let zoomStore: ZoomStore
    @ObservationIgnored private let settings: MirrorSettingsStoring
    @ObservationIgnored private let analytics: AnalyticsRecording
    @ObservationIgnored private var statusAdvisor = MirrorStatusAdvisor()
    @ObservationIgnored private let shortcutPrompt: ShortcutPromptServicing
    @ObservationIgnored private var isInBackground = false
    @ObservationIgnored private var isControlsVisible = false
    @ObservationIgnored private var faceSeenSince: TimeInterval?
    @ObservationIgnored private var isGuidePending = false
    @ObservationIgnored private var controlStateTask: Task<Void, Never>?

    init(camera: CameraServicing, lighting: LightingServicing, zoom: ZoomServicing,
         zoomStore: ZoomStore, renderer: MirrorRenderer, settings: MirrorSettingsStoring,
         analytics: AnalyticsRecording, shortcutPrompt: ShortcutPromptServicing) {
        self.camera = camera
        self.lighting = lighting
        self.zoom = zoom
        self.zoomStore = zoomStore
        self.renderer = renderer
        self.settings = settings
        self.analytics = analytics
        self.shortcutPrompt = shortcutPrompt
        isLargerButtons = settings.isLargerButtons
        lightPlacement = settings.lightPlacement
        isAnalyticsEnabled = analytics.isAnalyticsEnabled
    }

    var zoomState: ZoomState { zoomStore.zoomState }
    var zoomTarget: ZoomTarget { zoomStore.target }
    var zoomLevel: CGFloat { selectedPart.zoomTarget?.zoomScale ?? zoomState.scale }
    var zoomLevelText: String { "\((zoomLevel * 100).rounded() / 100)" }
    var cameraState: CameraState { camera.state }
    var permission: CameraPermissionStatus { cameraState == .permissionDenied ? .denied : .granted }
    var ringLightLevel: Double { UITestMode.forcesGlowMaximum ? 1 : lighting.ringLightLevel }
    var filterColor: ManualColorChoice? { lighting.filterColor }
    var glowProgress: CGFloat { GlowFrame.glowProgress(level: shownGlowLevel) }
    var glowOpacity: Double { GlowFrame.lightOpacity(level: shownGlowLevel) }

    func start() async {
        camera.start()
        zoom.start()
        analytics.appDidBecomeActive()
        recordAppOpen()
    }

    func refresh(startsCamera: Bool = true) {
        if startsCamera { camera.start() }
        zoom.start()
        analytics.appDidBecomeActive()
        guard isInBackground else { return }
        isInBackground = false
        recordAppOpen()
    }

    func pauseCamera() {
        camera.stop()
    }

    func stop() {
        lighting.setAuto(true)
        camera.stop()
        zoom.stop()
        analytics.appDidEnterBackground()
        isInBackground = true
        isShortcutPromptVisible = false
        isGuidePending = false
    }

    func setControlsVisible(_ isVisible: Bool) {
        isControlsVisible = isVisible
        if !isVisible { isShortcutPromptVisible = false }
    }

    func showShortcutGuide(fromPrompt: Bool) {
        analytics.shortcutGuideOpened(fromPrompt: fromPrompt)
        guard fromPrompt, isShortcutPromptVisible else {
            isShortcutGuideVisible = true
            return
        }
        isGuidePending = true
        isShortcutPromptVisible = false
    }

    func shortcutPromptDidDisappear() {
        guard isGuidePending else { return }
        isGuidePending = false
        isShortcutGuideVisible = true
    }

    func closeShortcutGuide() { isShortcutGuideVisible = false }

    func snoozeShortcutPrompt() { isShortcutPromptVisible = false }

    func dismissShortcutPromptForever() {
        isShortcutPromptVisible = false
        shortcutPrompt.dismissForever()
        analytics.shortcutPromptDismissedForever()
    }

    private func recordAppOpen() {
        shortcutPrompt.recordOpen()
        controlStateTask?.cancel()
        controlStateTask = Task { [weak self] in await self?.shortcutPrompt.refreshControlState() }
    }

    private func updateShortcutPrompt(now: TimeInterval) {
        if lighting.status.faceLux == nil {
            faceSeenSince = nil
        } else if faceSeenSince == nil {
            faceSeenSince = now
        }
        guard !isShortcutPromptVisible, !isShortcutGuideVisible else { return }
        let context = ShortcutPromptContext(isControlsVisible: isControlsVisible && permission == .granted,
                                            hasStatus: status != nil,
                                            faceSeenSeconds: faceSeenSince.map { now - $0 } ?? 0)
        guard shortcutPrompt.shouldShow(context) else { return }
        shortcutPrompt.markShown()
        isShortcutPromptVisible = true
        analytics.shortcutPromptShown()
    }

    func retryCamera() { camera.retry() }

    func openSettings() { camera.openSettings() }

    func select(_ part: FacePart) {
        let previous = selectedPart
        selectedPart = part
        if isOverallOn { setOverall(false) }
        zoom.select(part)
        analytics.partChanged(from: previous, to: part)
    }

    func setLightMode(_ mode: LightMode) {
        lightMode = mode
        lighting.setLightMode(mode)
        analytics.lightModeChanged(to: mode)
    }

    func setOverall(_ isOn: Bool) {
        isOverallOn = isOn
        zoom.setOverall(isOn)
    }
    
    func glowLevelDidChange(_ level: Double) {
        shownGlowLevel = GlowFrame.lightOpacity(level: level)
    }

    func replayTutorialOpened() { analytics.replayTutorialOpened() }

    func setLargerButtons(_ isOn: Bool) {
        isLargerButtons = isOn
        settings.isLargerButtons = isOn
    }

    func setLightPlacement(_ placement: LightPlacement) {
        lightPlacement = placement
        settings.lightPlacement = placement
    }

    func setAnalyticsEnabled(_ isOn: Bool) {
        isAnalyticsEnabled = isOn
        analytics.setAnalyticsEnabled(isOn)
    }

    func monitorStatus() async {
        while !Task.isCancelled {
            if permission == .denied { camera.start() }
            refreshStatus(now: ProcessInfo.processInfo.systemUptime)
            try? await Task.sleep(for: MirrorStatusConfig.refreshInterval)
        }
    }

    func refreshStatus(now: TimeInterval) {
        if isShortcutPromptVisible, cameraState == .reconnecting { snoozeShortcutPrompt() }
        if !isShortcutPromptVisible {
            let next = statusAdvisor.update(statusInput, now: now)
            if next != status {
                status = next
                analytics.statusChanged(to: next, faceLux: lighting.status.faceLux)
            }
        }
        updateShortcutPrompt(now: now)
    }

    func dismissStatus() {
        statusAdvisor.dismiss()
        status = nil
    }

    private var statusInput: MirrorStatusInput {
        let light = lighting.status
        let tracking = zoomStore.tracking
        let width = Double(tracking.face.width)
        let viewWidth = Double(tracking.viewSize.width)
        return MirrorStatusInput(isCameraPaused: cameraState == .reconnecting,
                                 isHeatLimited: light.isHeatLimited,
                                 faceLux: light.faceLux,
                                 isLightAtLimit: lightMode.isOn || light.isGlowAtMax,
                                 faceWidthRatio: width > 0 && viewWidth > 0 ? width / viewWidth : nil,
                                 zoomScale: Double(zoomState.scale))
    }

    func setReduceMotion(_ isOn: Bool) { zoom.setReduceMotion(isOn) }

    func setViewSize(_ size: CGSize) { zoom.setViewSize(size) }

    func pinchChanged(_ magnification: CGFloat) { zoom.pinchChanged(magnification) }

    func pinchEnded() {
        zoom.pinchEnded()
        analytics.pinchEnded(scale: Double(zoomState.scale))
        if selectedPart == .face { selectedPart = .smile }
    }

    func cameraStateDidChange(from old: CameraState, to new: CameraState) {
        analytics.cameraStateChanged(from: old, to: new)
        if new == .running, old != .running {
            zoom.resetSession()
        }
    }
}
