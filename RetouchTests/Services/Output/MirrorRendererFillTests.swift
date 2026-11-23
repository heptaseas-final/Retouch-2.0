//
//  MirrorRendererFillTests.swift
//  Retouch
//
//  Created by Retouch Team on 23/11/26.
//

import CoreGraphics
import Testing
@testable import Retouch

struct MirrorRendererFillTests {
    private let size = CGSize(width: 1179, height: 2556)

    @Test func coveredScreenNeedsNoFill() {
        let front = CGRect(x: -300, y: -300, width: size.width + 600, height: size.height + 600)
        #expect(!MirrorRenderer.needsFill(front, size: size))
    }

    @Test func exposedEdgeNeedsFill() {
        let front = CGRect(x: -300, y: -500, width: size.width + 600, height: size.height + 300)
        #expect(MirrorRenderer.needsFill(front, size: size))
    }

    @Test func edgeInsideTheFeatherNeedsFill() {
        let feather = size.width * ZoomTuning.faceLockFillFeather
        let front = CGRect(x: -feather / 2, y: -300, width: size.width + feather + 300, height: size.height + 600)
        #expect(MirrorRenderer.needsFill(front, size: size))
    }
}
