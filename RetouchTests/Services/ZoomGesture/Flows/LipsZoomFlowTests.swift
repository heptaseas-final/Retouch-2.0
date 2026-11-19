import Foundation
import Testing
@testable import Retouch

struct LipsZoomFlowTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1000)

    private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    private func toolInput(_ ready: Bool = true) -> LipsZoomFlow.Input {
        var input = LipsZoomFlow.Input()
        input.toolReady = ready
        return input
    }

    private func activeFlow() -> LipsZoomFlow {
        var flow = LipsZoomFlow()
        flow.update(toolInput(), now: at(0))
        flow.update(toolInput(), now: at(ZoomTuning.toolEnterDwell + 0.01))
        return flow
    }

    @Test func toolStaysEnteringBeforeDwell() {
        var flow = LipsZoomFlow()
        flow.update(toolInput(), now: at(0))
        flow.update(toolInput(), now: at(ZoomTuning.toolEnterDwell - 0.01))
        #expect(flow.phase == .entering)
        #expect(!flow.isActive)
    }

    @Test func toolActivatesAfterDwell() {
        let flow = activeFlow()
        #expect(flow.phase == .active)
        #expect(flow.trigger == .tool)
    }

    @Test func holdKeepsLipsActive() {
        var flow = activeFlow()
        var input = LipsZoomFlow.Input()
        input.fingerNear = true
        flow.update(input, now: at(5))
        #expect(flow.phase == .active)
    }

    @Test func releasesAfterReleaseDwellWithoutHold() {
        var flow = activeFlow()
        flow.update(LipsZoomFlow.Input(), now: at(2))
        #expect(flow.phase == .releasing)
        flow.update(LipsZoomFlow.Input(), now: at(2 + ZoomTuning.lipsReleaseDwell + 0.01))
        #expect(flow.phase == .idle)
    }

    @Test func talkingHoldEndsAfterWindow() {
        var flow = activeFlow()
        var near = LipsZoomFlow.Input()
        near.fingerNear = true
        flow.update(near, now: at(1))
        var talking = LipsZoomFlow.Input()
        talking.lipsMoving = true
        flow.update(talking, now: at(1 + ZoomTuning.softHoldWindow - 0.05))
        #expect(flow.phase == .active)
        flow.update(talking, now: at(1 + ZoomTuning.softHoldWindow + 0.05))
        #expect(flow.phase == .releasing)
    }

    @Test func handMovingAwayReleasesFast() {
        var flow = activeFlow()
        var input = LipsZoomFlow.Input()
        input.handMovingAway = true
        flow.update(input, now: at(2))
        flow.update(input, now: at(2 + ZoomTuning.fastReleaseDwell + 0.01))
        #expect(flow.phase == .idle)
    }

    @Test func handPathKeepsItsOwnDwell() {
        var flow = LipsZoomFlow()
        var input = LipsZoomFlow.Input()
        input.pose2Ready = true
        flow.update(input, now: at(0))
        flow.update(input, now: at(ZoomTuning.lipsEnterDwell + 0.01))
        #expect(flow.phase == .active)
        #expect(flow.trigger == .twoFinger)
    }
}
