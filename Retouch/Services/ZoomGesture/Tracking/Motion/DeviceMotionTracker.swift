import CoreMotion
import Foundation

nonisolated struct DeviceMotionSample: Equatable, Sendable {
    var tiltDown: Double
    var stillFor: TimeInterval
    var movingFor: TimeInterval
}

nonisolated final class DeviceMotionTracker: @unchecked Sendable {
    private let manager = CMMotionManager()
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "zoom.devicemotion"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        return queue
    }()
    private let lock = NSLock()
    private var tiltDown = 0.0
    private var stillSince: TimeInterval?
    private var movingSince: TimeInterval?
    private var hasSample = false

    deinit {
        manager.stopDeviceMotionUpdates()
    }

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1 / ZoomTuning.motionUpdateRate
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let motion else { return }
            self?.record(motion)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        lock.withLock {
            hasSample = false
            stillSince = nil
            movingSince = nil
        }
    }

    func sample(now: TimeInterval = ProcessInfo.processInfo.systemUptime) -> DeviceMotionSample? {
        lock.withLock {
            guard hasSample else { return nil }
            return DeviceMotionSample(tiltDown: tiltDown,
                                      stillFor: stillSince.map { max(now - $0, 0) } ?? 0,
                                      movingFor: movingSince.map { max(now - $0, 0) } ?? 0)
        }
    }

    private func record(_ motion: CMDeviceMotion) {
        let gravityZ = min(max(motion.gravity.z, -1), 1)
        let tilt = asin(gravityZ) * 180 / .pi
        let r = motion.rotationRate
        let a = motion.userAcceleration
        let rotation = (r.x * r.x + r.y * r.y + r.z * r.z).squareRoot()
        let acceleration = (a.x * a.x + a.y * a.y + a.z * a.z).squareRoot()
        let isMoving = rotation >= ZoomTuning.motionStillRotation
            || acceleration >= ZoomTuning.motionStillAcceleration
        let now = motion.timestamp
        lock.withLock {
            hasSample = true
            tiltDown = tilt
            if isMoving {
                stillSince = nil
                movingSince = movingSince ?? now
            } else {
                movingSince = nil
                stillSince = stillSince ?? now
            }
        }
    }
}
