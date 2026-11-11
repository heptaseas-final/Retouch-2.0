@testable import Retouch

@MainActor
final class FakeCameraService: CameraServicing {
    var state: CameraState = .idle
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var retryCount = 0
    private(set) var openSettingsCount = 0

    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func retry() { retryCount += 1 }
    func openSettings() { openSettingsCount += 1 }
}
