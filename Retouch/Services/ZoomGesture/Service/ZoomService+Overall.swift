import CoreGraphics
import Foundation

nonisolated extension ZoomService {
    func updatePose(face: FaceObservation?) {
        _ = overallRecognizer.update(face: face, motion: deviceMotion.sample(),
                                     now: ProcessInfo.processInfo.systemUptime)
    }

    func updateOverall(face: FaceObservation?, converter: CoordinateConverter) -> Bool {
        let wasShowing = isOverallShowing
        updatePose(face: face)
        isOverallShowing = overallRecognizer.pose != .none && (isOverallShowing || resolver.target == .fullFace)
        if wasShowing, !isOverallShowing, let face {
            faceTracker.reseedSize(face: face, converter: converter)
            distComp = DistanceCompensator()
        }
        return isOverallShowing
    }

    func setOverallOnly(_ isOn: Bool) {
        stateQueue.async { [self] in isOverallOnly = isOn }
    }

    func resetOverall() {
        overallRecognizer.reset()
        isOverallShowing = false
    }

    func overallScale() -> CGFloat {
        guard imageSize.width > 0, imageSize.height > 0, viewSize.width > 0, viewSize.height > 0 else { return 1 }
        let widthRatio = viewSize.width / imageSize.width
        let heightRatio = viewSize.height / imageSize.height
        return min(widthRatio, heightRatio) / max(widthRatio, heightRatio)
    }

    func publishOverall() {
        let center = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        send(scale: overallScale(), focus: .target(.overall, center))
    }
}
