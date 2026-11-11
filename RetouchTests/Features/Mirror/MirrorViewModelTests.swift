import Testing
@testable import Retouch

@MainActor
struct MirrorViewModelTests {
    let camera = FakeCameraService()
    let lighting = FakeLightingService()
    let zoom = FakeZoomService()

    func makeViewModel() -> MirrorViewModel {
        MirrorViewModel(camera: camera, lighting: lighting, zoom: zoom,
                        zoomStore: ZoomStore(), renderer: MirrorRenderer(device: nil))
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
