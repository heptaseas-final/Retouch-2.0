//
//  ZoomPart.swift
//  Retouch
//
//  Created by Davin P on 25/10/26.
//

enum ZoomPart: CaseIterable, Identifiable {
    case face, leftEye, rightEye, lips

    var id: Self { self }

    var systemName: String {
        switch self {
        case .face: "face.smiling.inverse"
        case .leftEye, .rightEye: "eye.fill"
        case .lips: "mouth.fill"
        }
    }

    var target: ZoomTarget {
        switch self {
        case .face: .fullFace
        case .leftEye: .leftEye
        case .rightEye: .rightEye
        case .lips: .lips
        }
    }

    var letter: String? {
        switch self {
        case .leftEye: "L"
        case .rightEye: "R"
        default: nil
        }
    }
}

enum FacePart: CaseIterable, Identifiable {
    case leftEye, rightEye, face, mouth, nose, smile

    var id: Self { self }

    var title: String {
        switch self {
        case .leftEye:  "LEFT EYE"
        case .rightEye: "RIGHT EYE"
        case .face:     "AUTO ZOOM"
        case .mouth:    "LIPS"
        case .nose:     "NOSE"
        case .smile:    "FULL FACE"
        }
    }
}

nonisolated extension FacePart {
    var zoomTarget: ZoomTarget? {
        switch self {
        case .face: nil
        case .leftEye: .leftEye
        case .rightEye: .rightEye
        case .mouth: .lips
        case .nose: .nose
        case .smile: .fullFace
        }
    }
}
