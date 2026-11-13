import Foundation
import Testing
@testable import Retouch

struct EyeZoomFlowTests {
    private let start = Date(timeIntervalSinceReferenceDate: 1000)

    private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    private func toolInput(left: Bool = false, right: Bool = false) -> EyeZoomFlow.Input {
        var input = EyeZoomFlow.Input()
        input.toolLeft = left
        input.toolRight = right
        return input
    }

    private func activeLeft() -> EyeZoomFlow {
        var flow = EyeZoomFlow()
        flow.update(toolInput(left: true), now: at(0))
        flow.update(toolInput(left: true), now: at(ZoomTuning.toolEnterDwell + 0.01))
        return flow
    }

    @Test func toolStaysEnteringBeforeDwell() {
        var flow = EyeZoomFlow()
        flow.update(toolInput(left: true), now: at(0))
        flow.update(toolInput(left: true), now: at(ZoomTuning.toolEnterDwell - 0.01))
        #expect(flow.phase == .entering)
        #expect(flow.target == nil)
    }

    @Test func toolLeftActivatesLeftEyeAfterDwell() {
        let flow = activeLeft()
        #expect(flow.phase == .active)
        #expect(flow.target == .leftEye)
    }

    @Test func toolRightActivatesRightEyeAfterDwell() {
        var flow = EyeZoomFlow()
        flow.update(toolInput(right: true), now: at(0))
        flow.update(toolInput(right: true), now: at(ZoomTuning.toolEnterDwell + 0.01))
        #expect(flow.target == .rightEye)
    }

    @Test func shortGapWithinGraceKeepsDwell() {
        var flow = EyeZoomFlow()
        flow.update(toolInput(left: true), now: at(0))
        flow.update(toolInput(), now: at(0.2))
        flow.update(toolInput(left: true), now: at(0.4))
        flow.update(toolInput(left: true), now: at(ZoomTuning.toolEnterDwell + 0.01))
        #expect(flow.target == .leftEye)
    }

    @Test func longGapResetsDwell() {
        var flow = EyeZoomFlow()
        flow.update(toolInput(left: true), now: at(0))
        flow.update(toolInput(), now: at(0.5))
        flow.update(toolInput(left: true), now: at(0.7))
        flow.update(toolInput(left: true), now: at(0.7 + ZoomTuning.toolEnterDwell - 0.01))
        #expect(flow.target == nil)
    }

    @Test func holdKeepsEyeActive() {
        var flow = activeLeft()
        var input = EyeZoomFlow.Input()
        input.holdLeft = true
        flow.update(input, now: at(5))
        #expect(flow.phase == .active)
    }

    @Test func releasesAfterReleaseDwellWithoutHold() {
        var flow = activeLeft()
        flow.update(EyeZoomFlow.Input(), now: at(2))
        #expect(flow.phase == .releasing)
        flow.update(EyeZoomFlow.Input(), now: at(2 + ZoomTuning.eyeFlowReleaseDwell - 0.01))
        #expect(flow.phase == .releasing)
        flow.update(EyeZoomFlow.Input(), now: at(2 + ZoomTuning.eyeFlowReleaseDwell + 0.01))
        #expect(flow.phase == .idle)
    }

    @Test func enterDwellsMatchSpec() {
        let flow = EyeZoomFlow()
        #expect(flow.enterDwell == 0.6)
        #expect(flow.gripDwell == 0.6)
        #expect(flow.pointDwell == 0.6)
        #expect(flow.toolDwell == 0.6)
        #expect(LipsZoomFlow().enterDwell == 0.6)
        #expect(LipsZoomFlow().gripDwell == 0.6)
    }

    @Test func releaseDwellMatchesSpecDecision() {
        #expect(ZoomTuning.eyeFlowReleaseDwell == 1.2)
        #expect(ZoomTuning.lipsReleaseDwell == 1.2)
    }

    @Test func toolOnOtherEyeSwitchesAfterDwell() {
        var flow = activeLeft()
        var input = toolInput(right: true)
        input.holdLeft = true
        flow.update(input, now: at(1))
        flow.update(input, now: at(1 + ZoomTuning.toolEnterDwell + 0.01))
        #expect(flow.target == .rightEye)
    }
}
