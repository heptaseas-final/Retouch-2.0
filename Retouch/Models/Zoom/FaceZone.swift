//
//  FaceZone.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 19/11/26.
//


import Foundation

nonisolated enum FaceZone: CaseIterable, Sendable {
    case leftEye, rightEye, nose, lips

    init?(target: ZoomTarget) {
        switch target {
        case .leftEye: self = .leftEye
        case .rightEye: self = .rightEye
        case .nose: self = .nose
        case .lips: self = .lips
        case .fullFace, .faceSide, .overall: return nil
        }
    }
}