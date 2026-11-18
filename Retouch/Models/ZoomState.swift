import CoreGraphics

nonisolated struct ZoomState: Equatable {
    var scale: CGFloat = 1
    var offset: CGSize = .zero
}

nonisolated struct ZoomTracking: Sendable {
    var target: ZoomTarget = .fullFace
    var face = FacePoints()
    var viewSize: CGSize = .zero
    var isFaceVisible = false
}

nonisolated enum FaceSide { case left, right }

nonisolated enum ZoomTarget: Equatable {
    case fullFace, leftEye, rightEye, lips, nose
    case faceSide(FaceSide)
    case overall

    var zoomScale: CGFloat {
        switch self {
        case .fullFace: ZoomTuning.fullFaceZoom
        case .overall: ZoomTuning.overallZoom
        case .leftEye, .rightEye: ZoomTuning.eyeZoomScale
        case .lips: ZoomTuning.lipsZoomScale
        case .nose: ZoomTuning.noseZoomScale
        case .faceSide: ZoomTuning.sideZoom
        }
    }

    var spokenName: String {
        switch self {
        case .fullFace: "Full face"
        case .leftEye: "Left eye"
        case .rightEye: "Right eye"
        case .lips: "Lips"
        case .nose: "Nose"
        case .faceSide(.left): "Left side of face"
        case .faceSide(.right): "Right side of face"
        case .overall: "Overall view"
        }
    }

    var zoomAnnouncement: String {
        switch self {
        case .fullFace: "Back to full face"
        case .overall: "Showing overall view"
        default: "Zoomed to \(spokenName.lowercased())"
        }
    }
}
