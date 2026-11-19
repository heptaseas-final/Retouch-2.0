//
//  ZoomTransitionTests.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//

import Foundation
import Testing
@testable import Retouch

struct ZoomTransitionTests {
    @Test("TC-3.5-07 Reduce Motion uses a 0.2 s cross-fade")
    func reduceMotionUsesCrossFade() {
        #expect(ZoomTransition.style(reduceMotion: true) == .crossFade(duration: 0.2))
    }

    @Test("TC-3.5-07 Cross-fade progress over 0.2 s",
          arguments: zip([0.0, 0.1, 0.2, 0.5], [0.0, 0.5, 1.0, 1.0]))
    func crossFadeProgress(elapsed: TimeInterval, expected: Double) {
        let transition = ZoomTransition.style(reduceMotion: true)
        #expect(abs(transition.fadeProgress(elapsed: elapsed) - expected) < 0.0001)
    }

    @Test("TC-5.4-06 Reduce Motion gives the same result as TC-3.5-07")
    func reduceMotionGivesSameResultAsZoomRule() {
        #expect(ZoomTransition.style(reduceMotion: true) == .crossFade(duration: 0.2))
        #expect(ZoomTransition.style(reduceMotion: false) == .zoom)
        #expect(ZoomTransition.style(reduceMotion: false).fadeProgress(elapsed: 0) == 1)
    }
}
