import CoreGraphics

nonisolated extension ZoomService {
    func cheekFocus(_ side: FaceSide, _ p: FacePoints) -> CGPoint? {
        guard let frame = FaceZoneFrame(points: p) else { return nil }
        let direction: CGFloat = side == .right ? 1 : -1
        let eyeX = side == .right ? frame.rightEyeX : frame.leftEyeX
        let reach = side == .right ? frame.rightEdgeX - eyeX : eyeX - frame.leftEdgeX
        let edge = max(reach, FaceZoneConfig.turnedMinEdge)
        return frame.view(x: eyeX + direction * edge * FaceZoneConfig.cheekFocusEdgeFraction,
                          y: FaceZoneConfig.cheekFocusY)
    }

    func isHeadStraight(_ layout: FaceZoneLayout) -> Bool {
        FaceZoneConfig.layoutDrivesHeadZoom ? layout == .frontal : headPose.isStraight
    }

    func layoutHeadTarget(_ layout: FaceZoneLayout) -> ZoomTarget? {
        switch layout {
        case .frontal: return nil
        case .turned(let visibleSide): return .faceSide(visibleSide)
        }
    }
}
