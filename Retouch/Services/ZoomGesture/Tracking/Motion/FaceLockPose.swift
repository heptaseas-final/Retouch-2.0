//
//  FaceLockPose.swift
//  Retouch
//
//  Created by Retouch Team on 23/11/26.
//

import CoreGraphics

nonisolated struct FaceLockPose: Equatable, Sendable {
    var face: CGPoint
    var entry: CGPoint
    var anchor: CGPoint
    var anchorScale: CGFloat
    var scale: CGFloat
    var weight: CGFloat
}
