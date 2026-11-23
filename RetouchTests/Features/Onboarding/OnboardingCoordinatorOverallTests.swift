import Testing
@testable import Retouch

@MainActor
struct OnboardingCoordinatorOverallTests {
    private func makeCoordinator(at step: OnboardingStep) -> OnboardingCoordinator {
        let coordinator = OnboardingCoordinator(analytics: FakeAnalyticsRecorder(), startingAt: step, onFinish: {})
        coordinator.start()
        return coordinator
    }

    @Test func overallStepsComeBeforeHappyRetouching() {
        #expect(OnboardingStep.tapToTurnOff.next == .overallIntro)
        #expect(OnboardingStep.overallIntro.next == .overallCheck)
        #expect(OnboardingStep.overallCheck.next == .tapRecording)
        #expect(OnboardingStep.tapRecording.next == .reviewRecording)
        #expect(OnboardingStep.reviewRecording.next == .done)
    }

    @Test func videoEndMovesToOverallCheck() {
        let coordinator = makeCoordinator(at: .overallIntro)
        coordinator.clipStateChanged(from: .empty, to: .recorded)
        #expect(coordinator.step == .overallIntro)
        coordinator.receive(.videoEnded)
        #expect(coordinator.step == .overallCheck)
    }

    @Test func recordedVideoMovesToTapRecording() {
        let coordinator = makeCoordinator(at: .overallCheck)
        coordinator.clipStateChanged(from: .empty, to: .recorded)
        #expect(coordinator.step == .tapRecording)
    }

    @Test func openingPreviewMovesToReview() {
        let coordinator = makeCoordinator(at: .tapRecording)
        coordinator.clipStateChanged(from: .recorded, to: .previewing)
        #expect(coordinator.step == .reviewRecording)
    }

    @Test func overallIntroReturnsToAutoZoom() {
        let coordinator = makeCoordinator(at: .tapToTurnOff)
        coordinator.selectPart(.leftEye)
        coordinator.flashTapped()
        #expect(coordinator.step == .overallIntro)
        #expect(coordinator.selectedPart == .face)
    }

    @Test func onlyOverallStepsBlockZoomIn() {
        let overallOnly = OnboardingStep.allCases.filter(\.isOverallOnly)
        #expect(overallOnly == [.overallIntro, .overallCheck, .tapRecording, .reviewRecording])
    }

    @Test(arguments: [OnboardingClipState.recorded, .empty])
    func closingPreviewMovesToDone(after state: OnboardingClipState) {
        let coordinator = makeCoordinator(at: .reviewRecording)
        coordinator.clipStateChanged(from: .previewing, to: state)
        #expect(coordinator.step == .done)
    }
}
