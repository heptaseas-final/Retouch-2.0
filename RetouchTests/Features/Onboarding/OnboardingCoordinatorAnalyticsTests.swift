import Testing
@testable import Retouch

@MainActor
struct OnboardingCoordinatorAnalyticsTests {
    private func makeCoordinator(_ analytics: FakeAnalyticsRecorder, onFinish: @escaping () -> Void = {}) -> OnboardingCoordinator {
        let coordinator = OnboardingCoordinator(analytics: analytics, onFinish: onFinish)
        coordinator.start()
        return coordinator
    }

    @Test func advancingReportsTheCompletedStep() {
        let analytics = FakeAnalyticsRecorder()
        let coordinator = makeCoordinator(analytics)
        coordinator.receive(.handNearEye)
        #expect(coordinator.step == .retouchKnows)
        #expect(analytics.calls == ["onboardingStarted", "onboardingStepCompleted(place_hand)"])
    }

    @Test func skipReportsCurrentStepAndFinishesOnce() {
        let analytics = FakeAnalyticsRecorder()
        var finishCount = 0
        let coordinator = makeCoordinator(analytics) { finishCount += 1 }
        coordinator.skip()
        coordinator.skip()
        #expect(analytics.calls == ["onboardingStarted", "onboardingSkipped(place_hand)"])
        #expect(finishCount == 1)
    }

    @Test func skipAfterAdvanceReportsTheLaterStep() {
        let analytics = FakeAnalyticsRecorder()
        let coordinator = makeCoordinator(analytics)
        coordinator.receive(.handNearEye)
        coordinator.skip()
        #expect(analytics.calls == ["onboardingStarted", "onboardingStepCompleted(place_hand)", "onboardingSkipped(retouch_knows)"])
    }

    @Test func stepNamesAreUniqueAndStable() {
        let names = OnboardingStep.allCases.map(\.analyticsName)
        #expect(Set(names).count == names.count)
        #expect(OnboardingStep.placeHand.analyticsName == "place_hand")
        #expect(OnboardingStep.done.analyticsName == "done")
    }
    
    @Test func startReportsOnboardingStartedOnce() {
        let analytics = FakeAnalyticsRecorder()
        let coordinator = makeCoordinator(analytics)
        coordinator.start()
        #expect(analytics.calls == ["onboardingStarted"])
    }
}
