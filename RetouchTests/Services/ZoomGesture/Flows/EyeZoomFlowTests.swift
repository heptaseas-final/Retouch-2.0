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
        #expect(flow.enterDwell == 0.35)
        #expect(flow.gripDwell == 0.35)
        #expect(flow.pointDwell == 0.35)
        #expect(flow.toolDwell == 0.35)
        #expect(LipsZoomFlow().enterDwell == 0.35)
        #expect(LipsZoomFlow().gripDwell == 0.35)
    }

    @Test func releaseDwellMatchesPmDecision() {
        #expect(ZoomTuning.eyeFlowReleaseDwell == 0.4)
        #expect(ZoomTuning.lipsReleaseDwell == 0.4)
        #expect(ZoomTuning.noseReleaseDwell == 0.4)
    }

    @Test func toolOnOtherEyeSwitchesAfterToolSwitchDwell() {
        var flow = activeLeft()
        var input = toolInput(right: true)
        input.holdLeft = true
        flow.update(input, now: at(1))
        flow.update(input, now: at(1 + ZoomTuning.toolSwitchDwell - 0.01))
        #expect(flow.target == .leftEye)
        flow.update(input, now: at(1 + ZoomTuning.toolSwitchDwell + 0.01))
        #expect(flow.target == .rightEye)
    }

    @Test func toolStillOnCurrentEyeBlocksToolSwitch() {
        var flow = activeLeft()
        var input = toolInput(right: true)
        input.holdLeft = true
        input.toolHoldLeft = true
        flow.update(input, now: at(1))
        flow.update(input, now: at(3))
        #expect(flow.target == .leftEye)
    }

    @Test func toolSwitchTimerRestartsWhenToolReturns() {
        var flow = activeLeft()
        var away = toolInput(right: true)
        away.holdLeft = true
        var back = away
        back.toolHoldLeft = true
        flow.update(away, now: at(1))
        flow.update(back, now: at(1.2))
        flow.update(away, now: at(1.3))
        flow.update(away, now: at(1.3 + ZoomTuning.toolSwitchDwell - 0.01))
        #expect(flow.target == .leftEye)
        flow.update(away, now: at(1.3 + ZoomTuning.toolSwitchDwell + 0.01))
        #expect(flow.target == .rightEye)
    }

    @Test func softHoldEndsAfterWindow() {
        var flow = activeLeft()
        var held = EyeZoomFlow.Input()
        held.holdLeft = true
        flow.update(held, now: at(1))
        var closing = EyeZoomFlow.Input()
        closing.activityLeft = .active
        flow.update(closing, now: at(1 + ZoomTuning.softHoldWindow - 0.05))
        #expect(flow.phase == .active)
        flow.update(closing, now: at(1 + ZoomTuning.softHoldWindow + 0.05))
        #expect(flow.phase == .releasing)
        flow.update(closing, now: at(1 + ZoomTuning.softHoldWindow + ZoomTuning.eyeFlowReleaseDwell + 0.1))
        #expect(flow.phase == .idle)
    }

    @Test func handMovingAwayReleasesFast() {
        var flow = activeLeft()
        var input = EyeZoomFlow.Input()
        input.handMovingAway = true
        flow.update(input, now: at(2))
        flow.update(input, now: at(2 + ZoomTuning.fastReleaseDwell + 0.01))
        #expect(flow.phase == .idle)
    }

    @Test func quickReentryUsesShortDwell() {
        var flow = activeLeft()
        flow.update(EyeZoomFlow.Input(), now: at(2))
        flow.update(EyeZoomFlow.Input(), now: at(2 + ZoomTuning.eyeFlowReleaseDwell + 0.01))
        #expect(flow.phase == .idle)
        let back = 2 + ZoomTuning.eyeFlowReleaseDwell + 0.5
        flow.update(toolInput(left: true), now: at(back))
        flow.update(toolInput(left: true), now: at(back + ZoomTuning.reentryDwell + 0.01))
        #expect(flow.target == .leftEye)
    }

    @Test func reentryAfterWindowUsesNormalDwell() {
        var flow = activeLeft()
        flow.update(EyeZoomFlow.Input(), now: at(2))
        flow.update(EyeZoomFlow.Input(), now: at(2 + ZoomTuning.eyeFlowReleaseDwell + 0.01))
        let back = 2 + ZoomTuning.eyeFlowReleaseDwell + ZoomTuning.reentryWindow + 0.5
        flow.update(toolInput(left: true), now: at(back))
        flow.update(toolInput(left: true), now: at(back + ZoomTuning.reentryDwell + 0.01))
        #expect(flow.target == nil)
    }
}
