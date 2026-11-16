//
//  ZoomRulesTests.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//

import CoreGraphics
import Foundation
import Testing
@testable import Retouch

struct ZoomRulesTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1_000)

    private func zoomedIntoLeftEye() -> ZoomGestureResolver {
        var resolver = ZoomGestureResolver()
        _ = resolver.resolve(hand: .leftEye, lips: false, head: nil, covering: false,
                             headStraight: true, now: start)
        return resolver
    }

    private func gestureOnRightEye(_ resolver: inout ZoomGestureResolver, after seconds: TimeInterval) -> ZoomTarget {
        resolver.resolve(hand: .rightEye, lips: false, head: nil, covering: false,
                         headStraight: true, now: start.addingTimeInterval(seconds))
    }

    private func headZoomedOut() -> (resolver: ZoomGestureResolver, changedAt: Date) {
        var resolver = ZoomGestureResolver()
        _ = resolver.resolve(hand: nil, lips: false, head: .faceSide(.left), covering: false,
                             headStraight: false, now: start)
        let changedAt = start.addingTimeInterval(0.5)
        _ = resolver.resolve(hand: nil, lips: false, head: nil, covering: false,
                             headStraight: true, now: changedAt)
        return (resolver, changedAt)
    }

    @Test("TC-3.5-04 Gesture during the cooldown")
    func gestureDuringCooldownIsIgnored() {
        var zoomed = headZoomedOut()
        #expect(zoomed.resolver.target == .fullFace)
        let target = zoomed.resolver.resolve(hand: nil, lips: false, head: .faceSide(.right), covering: false,
                                             headStraight: false, now: zoomed.changedAt.addingTimeInterval(1.0))
        #expect(target == .fullFace)
    }

    @Test("TC-3.5-05 Gesture after the cooldown")
    func gestureAfterCooldownIsAccepted() {
        var resolver = zoomedIntoLeftEye()
        #expect(resolver.target == .leftEye)
        let target = gestureOnRightEye(&resolver, after: 1.6)
        #expect(target == .rightEye)
    }

    @Test("TC-3.1-11 Detail at close zoom", arguments: [CGFloat(828), CGFloat(1179)])
    func upscaleAtCloseZoomIsAtMostTwo(outputWidth: CGFloat) {
        let captureShortSide: CGFloat = 2160
        let cropWidth = captureShortSide / ZoomTuning.eyeZoomScale
        let upscale = outputWidth / cropWidth
        #expect(upscale <= 2.0)
    }
}
