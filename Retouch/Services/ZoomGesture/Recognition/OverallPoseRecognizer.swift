import CoreGraphics
import Foundation

nonisolated struct OverallPoseRecognizer {
    private(set) var pose: OverallPose = .none
    private(set) var isRecordFar = false
    private(set) var isDismissed = false
    private var width: Double?
    private var highSince: TimeInterval?
    private var recordFarSince: TimeInterval?

    mutating func update(face: FaceObservation?, motion: DeviceMotionSample?, now: TimeInterval) -> OverallPose {
        if let face, face.width > 0 {
            let yaw = face.yaw.isFinite ? face.yaw * .pi / 180 : 0
            width = Double(face.width) / max(cos(yaw), ZoomTuning.overallMinYawCos)
        }
        guard let motion else {
            reset()
            return pose
        }
        releaseIfNeeded(motion)
        if pose == .none { isDismissed = false }
        updateRecordDistance(now: now)
        guard pose == .none, let width else { return pose }

        if motion.stillFor >= ZoomTuning.placedStillDwell, width <= ZoomTuning.placedEnterWidth {
            pose = .placedFar
            highSince = nil
            return pose
        }

        let tiltOK = motion.tiltDown >= ZoomTuning.highTiltEnter && motion.tiltDown <= ZoomTuning.highTiltMax
        guard tiltOK, width <= ZoomTuning.highEnterWidth else {
            highSince = nil
            return pose
        }
        let since = highSince ?? now
        highSince = since
        if now - since >= ZoomTuning.highEnterDwell {
            pose = .heldHigh
            highSince = nil
        }
        return pose
    }

    mutating func reset() {
        pose = .none
        width = nil
        highSince = nil
        isRecordFar = false
        recordFarSince = nil
        isDismissed = false
    }

    mutating func dismiss() {
        guard pose != .none else { return }
        isDismissed = true
        isRecordFar = false
        recordFarSince = nil
    }

    private mutating func updateRecordDistance(now: TimeInterval) {
        guard pose == .placedFar, !isDismissed, let width else {
            isRecordFar = false
            recordFarSince = nil
            return
        }
        if isRecordFar {
            if width > ZoomTuning.placedEnterWidth {
                isRecordFar = false
                recordFarSince = nil
            }
            return
        }
        guard width <= ZoomTuning.recordEnterWidth else {
            recordFarSince = nil
            return
        }
        let since = recordFarSince ?? now
        recordFarSince = since
        isRecordFar = now - since >= ZoomTuning.recordEnterDwell
    }

    private mutating func releaseIfNeeded(_ motion: DeviceMotionSample) {
        switch pose {
        case .none:
            break
        case .placedFar:
            let walkedForward = (width ?? 0) >= ZoomTuning.placedExitWidth
            let pickedUp = motion.movingFor >= ZoomTuning.placedMoveGrace
            if walkedForward || pickedUp { pose = .none }
        case .heldHigh:
            let lowered = motion.tiltDown < ZoomTuning.highTiltExit
            let tooClose = (width ?? 0) > ZoomTuning.highExitWidth
            if lowered || tooClose { pose = .none }
        }
    }
}
