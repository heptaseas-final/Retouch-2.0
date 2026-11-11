import Observation
import UIKit

protocol CameraServicing: AnyObject {
    var state: CameraState { get }
    func start()
    func stop()
    func retry()
    func openSettings()
}

protocol CameraLifecycleListening: AnyObject {
    func cameraWillStart()
    func cameraDidStop(isStarted: Bool)
    func appActiveDidChange(_ isActive: Bool, isStarted: Bool)
    func cameraStateDidChange(to state: CameraState, isStarted: Bool)
}

@Observable
final class CameraService: CameraServicing {
    private(set) var state: CameraState = .idle
    @ObservationIgnored private(set) var isAppActive = UIApplication.shared.applicationState == .active
    @ObservationIgnored weak var lifecycleListener: CameraLifecycleListening?

    @ObservationIgnored private let camera: CameraSessionManager
    @ObservationIgnored private var isStarted = false
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init(camera: CameraSessionManager) {
        self.camera = camera
        camera.onStateChange = { [weak self] in self?.stateChanged($0) }
        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.setAppActive(false) }
            },
            center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.setAppActive(true) }
            },
            center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.enterBackground() }
            },
            center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.enterForeground() }
            },
        ]
    }

    func start() {
        guard !(isStarted && state == .running) else { return }
        isStarted = true
        UIApplication.shared.isIdleTimerDisabled = true
        lifecycleListener?.cameraWillStart()
        camera.start()
    }

    func stop() {
        isStarted = false
        UIApplication.shared.isIdleTimerDisabled = false
        camera.stop()
        lifecycleListener?.cameraDidStop(isStarted: isStarted)
    }

    func retry() {
        guard isStarted else { return start() }
        camera.retry()
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func setAppActive(_ isActive: Bool) {
        isAppActive = isActive
        lifecycleListener?.appActiveDidChange(isActive, isStarted: isStarted)
    }

    private func enterBackground() {
        guard isStarted else { return }
        UIApplication.shared.isIdleTimerDisabled = false
        camera.stop(reportAs: .reconnecting)
        lifecycleListener?.cameraDidStop(isStarted: isStarted)
    }

    private func enterForeground() {
        guard isStarted else { return }
        start()
    }

    private func stateChanged(_ newState: CameraState) {
        state = newState
        lifecycleListener?.cameraStateDidChange(to: newState, isStarted: isStarted)
    }
}
