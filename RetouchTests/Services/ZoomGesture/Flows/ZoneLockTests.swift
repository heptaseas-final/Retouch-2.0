//
//  ZoneLockTests.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 19/11/26.
//


import Foundation
import Testing
@testable import Retouch

struct ZoneLockTests {
    private let start = Date(timeIntervalSinceReferenceDate: 3000)

    private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    @Test func switchDwellIsSharedAndLongerThanEntry() {
        #expect(ZoomTuning.zoneSwitchDwell > ZoomTuning.toolEnterDwell)
        #expect(ZoomTuning.toolSwitchDwell == ZoomTuning.zoneSwitchDwell)
        #expect(ZoomTuning.eyeFlowSwitchDwell == ZoomTuning.zoneSwitchDwell)
    }

    @Test func lipsWaitForFloorWhileAnotherZoneShows() {
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

    @Test func noseWaitsForFloorWhileAnotherZoneShows() {
        var flow = NoseZoomFlow()
        var input = NoseZoomFlow.Input()
        input.toolReady = true
        input.enterFloor = ZoomTuning.zoneSwitchDwell
        flow.update(input, now: at(0))
        flow.update(input, now: at(ZoomTuning.zoneSwitchDwell - 0.01))
        #expect(flow.phase == .entering)
        flow.update(input, now: at(ZoomTuning.zoneSwitchDwell + 0.01))
        #expect(flow.phase == .active)
    }

    @Test func eyeWaitsForFloorWhileAnotherZoneShows() {
        var flow = EyeZoomFlow()
        var input = EyeZoomFlow.Input()
        input.toolLeft = true
        input.enterFloor = ZoomTuning.zoneSwitchDwell
        flow.update(input, now: at(0))
        flow.update(input, now: at(ZoomTuning.zoneSwitchDwell - 0.01))
        #expect(flow.target == nil)
        flow.update(input, now: at(ZoomTuning.zoneSwitchDwell + 0.01))
        #expect(flow.target == .leftEye)
    }

    @Test func noFloorKeepsNormalEntry() {
        var flow = LipsZoomFlow()
        var input = LipsZoomFlow.Input()
        input.toolReady = true
        flow.update(input, now: at(0))
        flow.update(input, now: at(ZoomTuning.toolEnterDwell + 0.01))
        #expect(flow.phase == .active)
    }

    @Test func eyeStaysOnCurrentSideWhileSwitchIsPending() {
        var flow = EyeZoomFlow()
        var left = EyeZoomFlow.Input()
        left.toolLeft = true
        flow.update(left, now: at(0))
        flow.update(left, now: at(ZoomTuning.toolEnterDwell + 0.01))
        var right = EyeZoomFlow.Input()
        right.toolRight = true
        flow.update(right, now: at(1))
        flow.update(right, now: at(1 + ZoomTuning.toolSwitchDwell - 0.01))
        #expect(flow.phase == .active)
        #expect(flow.target == .leftEye)
        flow.update(right, now: at(1 + ZoomTuning.toolSwitchDwell + 0.01))
        #expect(flow.target == .rightEye)
    }
}
