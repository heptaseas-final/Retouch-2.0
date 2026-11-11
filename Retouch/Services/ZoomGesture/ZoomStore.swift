import Foundation
import Observation

@Observable
final class ZoomStore {
    typealias TrackingListener = (ZoomTracking, ZoomState) -> Void

    private(set) var zoomState = ZoomState()
    private(set) var tracking = ZoomTracking()

    @ObservationIgnored private var listeners: [UUID: TrackingListener] = [:]

    @discardableResult
    func addTrackingListener(_ listener: @escaping TrackingListener) -> UUID {
        let id = UUID()
        listeners[id] = listener
        return id
    }

    func removeTrackingListener(_ id: UUID) {
        listeners[id] = nil
    }

    func update(_ state: ZoomState) {
        zoomState = state
        notify()
    }

    func update(_ value: ZoomTracking) {
        tracking = value
        notify()
    }

    private func notify() {
        for listener in listeners.values { listener(tracking, zoomState) }
    }
}
