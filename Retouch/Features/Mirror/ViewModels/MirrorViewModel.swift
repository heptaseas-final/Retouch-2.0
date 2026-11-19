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

    @ObservationIgnored let renderer: MirrorRenderer
    @ObservationIgnored private let camera: CameraServicing
    @ObservationIgnored private let lighting: LightingServicing
    @ObservationIgnored private let zoom: ZoomServicing
    @ObservationIgnored private let zoomStore: ZoomStore
    @ObservationIgnored private let settings: MirrorSettingsStoring
    @ObservationIgnored private let analytics: AnalyticsRecording
    @ObservationIgnored private var statusAdvisor = MirrorStatusAdvisor()

    init(camera: CameraServicing, lighting: LightingServicing, zoom: ZoomServicing,
         zoomStore: ZoomStore, renderer: MirrorRenderer, settings: MirrorSettingsStoring,
         analytics: AnalyticsRecording) {
        self.camera = camera
        self.lighting = lighting
        self.zoom = zoom
        self.zoomStore = zoomStore
        self.renderer = renderer
        self.settings = settings
        self.analytics = analytics
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
    var ringLightWidth: CGFloat { CGFloat(lighting.config.ringLightWidth) }
    var ringLightSoftness: Double { lighting.config.ringLightSoftness }
    var filterColor: ManualColorChoice? { lighting.filterColor }
    var closeness: Double { lighting.closeness }

    func start() async {
        camera.start()
        zoom.start()
        analytics.appDidBecomeActive()
    }

    func refresh() {
        camera.start()
        zoom.start()
        analytics.appDidBecomeActive()
    }

    func stop() {
        lighting.setAuto(true)
        camera.stop()
        zoom.stop()
        analytics.appDidEnterBackground()
    }

    func retryCamera() { camera.retry() }

    func openSettings() { camera.openSettings() }

    func select(_ part: FacePart) {
        let previous = selectedPart
        selectedPart = part
        zoom.select(part)
        analytics.partChanged(from: previous, to: part)
    }

    func setLightMode(_ mode: LightMode) {
        lightMode = mode
        lighting.setLightMode(mode)
        analytics.lightModeChanged(to: mode)
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
        let next = statusAdvisor.update(statusInput, now: now)
        if next != status {
            status = next
            analytics.statusChanged(to: next, faceLux: lighting.status.faceLux)
        }
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
