import Foundation
import Testing
@testable import Retouch

struct NoseZoomFlowTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1000)

    private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    private func toolInput(_ ready: Bool = true) -> NoseZoomFlow.Input {
        var input = NoseZoomFlow.Input()
        input.toolReady = ready
        return input
    }

    private func activeFlow() -> NoseZoomFlow {
        var flow = NoseZoomFlow()
        flow.update(toolInput(), now: at(0))
        flow.update(toolInput(), now: at(ZoomTuning.toolEnterDwell + 0.01))
        return flow
    }

    @Test func brushStaysEnteringBeforeDwell() {
        var flow = NoseZoomFlow()
        flow.update(toolInput(), now: at(0))
        flow.update(toolInput(), now: at(ZoomTuning.toolEnterDwell - 0.01))
        #expect(flow.phase == .entering)
        #expect(!flow.isActive)
    }

    @Test func brushActivatesNoseAfterDwell() {
        let flow = activeFlow()
        #expect(flow.phase == .active)
        #expect(flow.trigger == .tool)
    }

    @Test func toolHoldKeepsNoseActive() {
        var flow = activeFlow()
        var input = NoseZoomFlow.Input()
        input.fingerNear = true
        flow.update(input, now: at(5))
        #expect(flow.phase == .active)
    }

    @Test func releasesAfterReleaseDwell() {
        var flow = activeFlow()
        flow.update(NoseZoomFlow.Input(), now: at(2))
        #expect(flow.phase == .releasing)
        flow.update(NoseZoomFlow.Input(), now: at(2 + ZoomTuning.noseReleaseDwell + 0.01))
        #expect(flow.phase == .idle)
    }

    @Test func handMovingAwayReleasesFast() {
        var flow = activeFlow()
        var input = NoseZoomFlow.Input()
        input.handMovingAway = true
        flow.update(input, now: at(2))
        flow.update(input, now: at(2 + ZoomTuning.fastReleaseDwell + 0.01))
        #expect(flow.phase == .idle)
    }
}
