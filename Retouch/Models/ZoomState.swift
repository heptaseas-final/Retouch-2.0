//
//  ZoomState.swift
//  Retouch
//
//  Created by Davin P on 25/10/26.
//

import CoreGraphics

nonisolated struct ZoomState: Equatable {
    var scale: CGFloat = 1
    var offset: CGSize = .zero
}

nonisolated struct ZoomTracking: Sendable {
    var target: ZoomTarget = .fullFace
    var face = FacePoints()
    var viewSize: CGSize = .zero
}

nonisolated enum FaceSide { case left, right }

nonisolated enum ZoomTarget: Equatable {
    case fullFace, leftEye, rightEye, lips, nose
    case faceSide(FaceSide)

    var zoomScale: CGFloat {
        switch self {
        case .fullFace: ZoomTuning.fullFaceZoom
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
        }
    }

    var zoomAnnouncement: String {
        self == .fullFace ? "Back to full face" : "Zoomed to \(spokenName.lowercased())"
    }
}
