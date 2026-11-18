import CoreGraphics

nonisolated extension ZoomService {
    func updateOverall(face: FaceObservation?, converter: CoordinateConverter) -> Bool {
        let wasShowing = isOverallShowing
        if let face { armReach.update(faceWidth: face.width, yawDegrees: face.yaw) }
        isOverallShowing = armReach.isReaching && (isOverallShowing || resolver.target == .fullFace)
        if wasShowing, !isOverallShowing, let face {
            faceTracker.reseedSize(face: face, converter: converter)
            distComp = DistanceCompensator()
        }
        return isOverallShowing
    }

    func resetOverall() {
        armReach.reset()
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
