//
//  CheekZoomFlowTests.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 20/11/26.
//


import Foundation
import Testing
@testable import Retouch

struct CheekZoomFlowTests {
    private let start = Date(timeIntervalSinceReferenceDate: 5000)

    private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    private func readyRight() -> CheekZoomFlow.Input {
        var input = CheekZoomFlow.Input()
        input.readyRight = true
        return input
    }

    private func activeRight() -> CheekZoomFlow {
        var flow = CheekZoomFlow()
        flow.update(readyRight(), now: at(0))
        flow.update(readyRight(), now: at(ZoomTuning.cheekEnterDwell + 0.01))
        return flow
    }

    @Test func staysEnteringBeforeDwell() {
        var flow = CheekZoomFlow()
        flow.update(readyRight(), now: at(0))
        flow.update(readyRight(), now: at(ZoomTuning.cheekEnterDwell - 0.01))
        #expect(flow.phase == .entering)
        #expect(flow.target == nil)
    }

    @Test func activatesTheReadySideAfterDwell() {
        let flow = activeRight()
        #expect(flow.phase == .active)
        #expect(flow.target == .cheek(.right))
    }

    @Test func waitsForFloorWhileAnotherZoneShows() {
        var flow = CheekZoomFlow()
        var input = readyRight()
        input.enterFloor = ZoomTuning.cheekEnterDwell + 0.3
        flow.update(input, now: at(0))
        flow.update(input, now: at(ZoomTuning.cheekEnterDwell + 0.1))
        #expect(flow.target == nil)
        flow.update(input, now: at(input.enterFloor + 0.01))
        #expect(flow.target == .cheek(.right))
    }

    @Test func handNearKeepsCheekActive() {
        var flow = activeRight()
        var near = CheekZoomFlow.Input()
        near.nearRight = true
        flow.update(near, now: at(5))
        #expect(flow.phase == .active)
    }

    @Test func releasesAfterGraceAndReleaseDwell() {
        var flow = activeRight()
        let released = ZoomTuning.cheekEnterDwell + 0.01 + ZoomTuning.holdGrace + 0.05
        flow.update(CheekZoomFlow.Input(), now: at(released))
        #expect(flow.phase == .releasing)
        flow.update(CheekZoomFlow.Input(), now: at(released + ZoomTuning.cheekReleaseDwell + 0.01))
        #expect(flow.phase == .idle)
        #expect(flow.target == nil)
    }

    @Test func handMovingAwayReleasesFast() {
        var flow = activeRight()
        var away = CheekZoomFlow.Input()
        away.handMovingAway = true
        let released = ZoomTuning.cheekEnterDwell + 0.01 + ZoomTuning.holdGrace + 0.05
        flow.update(away, now: at(released))
        flow.update(away, now: at(released + ZoomTuning.fastReleaseDwell + 0.01))
        #expect(flow.phase == .idle)
    }

    @Test func cancelGoesIdle() {
        var flow = activeRight()
        flow.cancel()
        #expect(flow.phase == .idle)
        #expect(flow.target == nil)
    }
}