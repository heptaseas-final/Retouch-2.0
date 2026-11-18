import Foundation

nonisolated struct ArmReachRecognizer {
    private(set) var isReaching = false

    mutating func update(faceWidth: CGFloat, yawDegrees: Double) {
        guard faceWidth > 0 else { return }
        let yaw = yawDegrees.isFinite ? yawDegrees * .pi / 180 : 0
        let width = Double(faceWidth) / max(cos(yaw), ZoomTuning.overallMinYawCos)
        if isReaching {
            if width >= ZoomTuning.overallExitWidth { isReaching = false }
        } else if width <= ZoomTuning.overallEnterWidth {
            isReaching = true
        }
    }

    mutating func reset() {
        isReaching = false
    }
}
