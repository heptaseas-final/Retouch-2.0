import Foundation

final class AppContainer {
    let cameraSession = CameraSessionManager()
    let camera: CameraService
    let lightingEngine: LightingEngine
    let lighting: LightingService
    let pipeline: FramePipeline
    let zoom: ZoomServicing
    let zoomStore = ZoomStore()
    let analytics: AnalyticsRecorder
    let mirrorViewModel: MirrorViewModel
    let clipRecording: ClipRecordingServicing
    let photoLibrary = PhotoLibraryService()
    let clipReviewViewModel: ClipReviewViewModel

    init() {
        let config = LightingConfig()
        cameraSession.prefersAutoFrameRate = config.autoFrameRateInDark
        camera = CameraService(camera: cameraSession)
        lightingEngine = LightingEngine(camera: cameraSession, config: config)
        lighting = LightingService(engine: lightingEngine, brightnessController: BrightnessController(),
                                   isAppActive: camera.isAppActive)
        camera.lifecycleListener = lighting
        pipeline = FramePipeline(lighting: lightingEngine)
        cameraSession.onFrame = { [pipeline] frame in pipeline.process(frame) }
        zoom = ZoomService()
        analytics = AnalyticsRecorder(service: AnalyticsService(), zoomStore: zoomStore, lighting: lighting)
        mirrorViewModel = MirrorViewModel(camera: camera, lighting: lighting, zoom: zoom,
                                          zoomStore: zoomStore, renderer: pipeline.renderer,
                                          settings: MirrorSettingsStore(), analytics: analytics)
        connectZoom()
        connectClipRecording()
    }

    func makeOnboardingSignals() -> ZoomOnboardingSignals {
        ZoomOnboardingSignals(store: zoomStore, zoom: zoom, lighting: lighting)
    }

    private func connectZoom() {
        let store = zoomStore
        zoom.onZoomChange = { state in
            Task { @MainActor [weak store = store] in store?.update(state) }
        }
        zoom.onTracking = { tracking in
            Task { @MainActor [weak store = store] in store?.update(tracking) }
        }
        pipeline.vision.setHandler { [zoom] buffer in
            zoom.process(buffer)
        }
    }

    private func connectClipRecording() {
        let recording = clipRecording
        pipeline.onOutputFrame = { image, time in recording.append(image, time: time) }
        zoomStore.addTrackingListener { tracking, _ in recording.noteTracking(tracking) }
    }
}
