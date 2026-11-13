import Testing
@testable import Retouch

@MainActor
struct MirrorViewModelTests {
    let camera = FakeCameraService()
    let lighting = FakeLightingService()
    let zoom = FakeZoomService()
    let settings = FakeMirrorSettingsStore()

    func makeViewModel() -> MirrorViewModel {
        MirrorViewModel(camera: camera, lighting: lighting, zoom: zoom,
                        zoomStore: ZoomStore(), renderer: MirrorRenderer(device: nil), settings: settings)
    }

    @Test func loadsSavedSettings() {
        settings.isLargerButtons = true
        settings.lightPlacement = .right
        let viewModel = makeViewModel()
        #expect(viewModel.isLargerButtons)
        #expect(viewModel.lightPlacement == .right)
    }

    @Test func changingSettingsSavesThem() {
        let viewModel = makeViewModel()
        viewModel.setLargerButtons(true)
        viewModel.setLightPlacement(.left)
        #expect(viewModel.isLargerButtons && settings.isLargerButtons)
        #expect(viewModel.lightPlacement == .left && settings.lightPlacement == .left)
    }

    @Test func lowLightStatusAppearsAndCanBeDismissed() {
        let viewModel = makeViewModel()
        viewModel.setLightMode(.on(.white))
        lighting.status = LightingStatus(faceLux: 100)
        viewModel.refreshStatus(now: 0)
        viewModel.refreshStatus(now: 2)
        #expect(viewModel.status == .notEnoughLight)
        viewModel.dismissStatus()
        viewModel.refreshStatus(now: 3)
        #expect(viewModel.status == nil)
    }

    @Test func reduceMotionIsForwardedToZoom() {
        let viewModel = makeViewModel()
        viewModel.setReduceMotion(true)
        #expect(zoom.reduceMotionValues == [true])
    }

    @Test func selectingPartUpdatesStateAndZoom() {
        let viewModel = makeViewModel()
        viewModel.select(.mouth)
        #expect(viewModel.selectedPart == .mouth)
        #expect(zoom.selectedParts == [.mouth])
    }

    @Test func settingLightModeForwardsToLighting() {
        let viewModel = makeViewModel()
        viewModel.setLightMode(.on(.warm))
        #expect(viewModel.lightMode == .on(.warm))
        #expect(lighting.lightModes == [.on(.warm)])
    }

    @Test func stopRestoresAutoLightAndStopsServices() {
        let viewModel = makeViewModel()
        viewModel.stop()
        #expect(lighting.autoCalls == [true])
        #expect(camera.stopCount == 1)
        #expect(zoom.stopCount == 1)
    }

    @Test func deniedCameraReportsDeniedPermission() {
        camera.state = .permissionDenied
        #expect(makeViewModel().permission == .denied)
    }

    @Test func cameraRunningAgainResetsZoomSession() {
        let viewModel = makeViewModel()
        viewModel.cameraStateDidChange(from: .reconnecting, to: .running)
        viewModel.cameraStateDidChange(from: .running, to: .running)
        #expect(zoom.resetCount == 1)
    }
}
