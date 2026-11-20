import Foundation
@testable import Retouch

@MainActor
final class FakeAnalyticsRecorder: AnalyticsRecording {
    private(set) var calls: [String] = []
    var isAnalyticsEnabled = true

    func appDidBecomeActive() { calls.append("appDidBecomeActive") }

    func appDidEnterBackground() { calls.append("appDidEnterBackground") }

    func cameraStateChanged(from old: CameraState, to new: CameraState) { calls.append("cameraStateChanged") }

    func partChanged(from old: FacePart, to new: FacePart) { calls.append("partChanged") }

    func lightModeChanged(to mode: LightMode) { calls.append("lightModeChanged") }

    func pinchEnded(scale: Double) { calls.append("pinchEnded") }

    func statusChanged(to status: MirrorStatus?, faceLux: Double?) { calls.append("statusChanged") }

    func replayTutorialOpened() { calls.append("replayTutorialOpened") }

    func shortcutPromptShown() { calls.append("shortcutPromptShown") }

    func shortcutGuideOpened(fromPrompt: Bool) { calls.append("shortcutGuideOpened(\(fromPrompt))") }

    func shortcutPromptDismissedForever() { calls.append("shortcutPromptDismissedForever") }

    func onboardingStepCompleted(step: String) { calls.append("onboardingStepCompleted(\(step))") }

    func onboardingSkipped(step: String) { calls.append("onboardingSkipped(\(step))") }

    func onboardingCompleted() { calls.append("onboardingCompleted") }

    func setAnalyticsEnabled(_ isEnabled: Bool) {
        isAnalyticsEnabled = isEnabled
        calls.append("setAnalyticsEnabled")
    }
}
