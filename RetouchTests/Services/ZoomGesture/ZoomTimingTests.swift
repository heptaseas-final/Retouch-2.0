//
//  ZoomTimingTests.swift
//  Retouch
//
//  Created by Davin P on 19/11/26.
//

import Foundation
import Testing
@testable import Retouch

struct ZoomTimingTests {
    private let start = Date(timeIntervalSinceReferenceDate: 2000)

    private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    private func tool(left: Bool = false, right: Bool = false) -> EyeZoomFlow.Input {
        var input = EyeZoomFlow.Input()
        input.toolLeft = left
        input.toolRight = right
        return input
    }

    private func leftActive() -> EyeZoomFlow {
        var flow = EyeZoomFlow()
        flow.update(tool(left: true), now: at(0))
        flow.update(tool(left: true), now: at(ZoomTuning.toolEnterDwell + 0.01))
        return flow
    }

    @Test func eyeToEyeSwitchWaitsForZoneLock() {
        var flow = leftActive()
        var input = tool(right: true)
        input.holdLeft = true
        flow.update(input, now: at(1))
        flow.update(input, now: at(1 + ZoomTuning.toolSwitchDwell - 0.01))
        #expect(flow.target == .leftEye)
        flow.update(input, now: at(1 + ZoomTuning.toolSwitchDwell + 0.01))
        #expect(flow.target == .rightEye)
        #expect(ZoomTuning.toolSwitchDwell == ZoomTuning.zoneSwitchDwell)
    }

    @Test func fingerSwitchUsesSwitchDwell() {
        var flow = leftActive()
        var input = EyeZoomFlow.Input()
        input.holdLeft = true
        input.pointRight = true
        flow.update(input, now: at(1))
        flow.update(input, now: at(1 + ZoomTuning.eyeFlowSwitchDwell + 0.01))
        #expect(flow.target == .rightEye)
    }

    @Test func eyeToMouthWaitsForZoneLock() {
        var flow = LipsZoomFlow()
        var input = LipsZoomFlow.Input()
        input.toolReady = true
        input.enterFloor = ZoomTuning.zoneSwitchDwell
        flow.update(input, now: at(0))
        flow.update(input, now: at(ZoomTuning.zoneSwitchDwell - 0.01))
        #expect(flow.phase == .entering)
        flow.update(input, now: at(ZoomTuning.zoneSwitchDwell + 0.01))
        #expect(flow.phase == .active)
    }

    @Test func eyeReleasesWithinHalfSecondWhenFaceStraightAndHandClear() {
        var flow = leftActive()
        var input = EyeZoomFlow.Input()
        input.handMovingAway = true
        flow.update(input, now: at(2))
        flow.update(input, now: at(2 + ZoomTuning.fastReleaseDwell + 0.01))
        #expect(flow.phase == .idle)
    }

    @Test func resolverZoomsOutQuicklyAfterHandLeaves() {
        var resolver = ZoomGestureResolver()
        _ = resolver.resolve(hand: .leftEye, lips: false, head: nil, covering: false, headStraight: true, now: at(0))
        _ = resolver.resolve(hand: nil, lips: false, head: nil, covering: false, headStraight: true, now: at(0.1))
        #expect(resolver.target == .fullFace)
    }

    @Test func coverHoldIsShort() {
        #expect(ZoomTuning.coverHold <= 1.0)
        #expect(ZoomTuning.resolverExitCooldown <= 0.6)
    }
}
