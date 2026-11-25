//
//  ZoomAnimatorRestTests.swift
//  Retouch
//
//  Created by Retouch Team on 23/11/26.
//

import Testing
@testable import Retouch

struct ZoomAnimatorRestTests {
    @Test func startsAtFullFaceScale() {
        let animator = ZoomAnimator()
        #expect(animator.displayedScale == ZoomTuning.fullFaceZoom)
    }

    @Test func resetReturnsToFullFaceScale() {
        let animator = ZoomAnimator()
        animator.reset()
        #expect(animator.displayedScale == ZoomTuning.fullFaceZoom)
    }

    @Test func fullFaceScaleKeepsTheStabilizerMargin() {
        #expect(ZoomTuning.fullFaceZoom > 1.001)
        #expect(ZoomTarget.fullFace.zoomScale == ZoomTuning.fullFaceZoom)
    }
}
