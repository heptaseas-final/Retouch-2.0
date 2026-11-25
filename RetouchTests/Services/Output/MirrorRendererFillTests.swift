//
//  MirrorRendererFillTests.swift
//  Retouch
//
//  Created by Retouch Team on 23/11/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import Retouch

struct MirrorRendererFillTests {
    private let size = CGSize(width: 1179, height: 2556)
    private let extent = CGRect(x: 0, y: 0, width: 1440, height: 1920)
    private var scale: CGFloat { max(size.width / extent.width, size.height / extent.height) * 1.15 }

    @Test func coveredScreenNeedsNoFill() {
        #expect(!MirrorRenderer.needsFill(placed(), extent: extent, scale: scale, size: size))
    }

    @Test func shiftedFrameNeedsFill() {
        #expect(MirrorRenderer.needsFill(placed(shiftY: 300), extent: extent, scale: scale, size: size))
    }

    @Test func strongTiltNeedsFill() {
        #expect(MirrorRenderer.needsFill(placed(angle: 0.61), extent: extent, scale: scale, size: size))
    }

    private func placed(shiftY: CGFloat = 0, angle: CGFloat = 0) -> CGAffineTransform {
        CGAffineTransform(translationX: -extent.midX, y: -extent.midY)
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(rotationAngle: angle))
            .concatenating(CGAffineTransform(translationX: size.width / 2, y: size.height / 2 + shiftY))
    }
}
