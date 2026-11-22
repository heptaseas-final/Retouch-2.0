import Testing
@testable import Retouch

@MainActor
struct MirrorViewModelTests {
    let camera = FakeCameraService()
    let lighting = FakeLightingService()
    let zoom = FakeZoomService()
    let settings = FakeMirrorSettingsStore()
    let analytics = FakeAnalyticsRecorder()
    let shortcutPrompt = FakeShortcutPromptService()

    func makeViewModel() -> MirrorViewModel {
        MirrorViewModel(camera: camera, lighting: lighting, zoom: zoom,
                        zoomStore: ZoomStore(), renderer: MirrorRenderer(device: nil), settings: settings, analytics: analytics,
                        shortcutPrompt: shortcutPrompt)
    }

    @Test func coldLaunchCountsOneOpen() async {
        let viewModel = makeViewModel()
        await viewModel.start()
        viewModel.refresh()
        #expect(shortcutPrompt.openCount == 1)
    }

    @Test func returningFromBackgroundCountsAnOpenButInactiveDoesNot() async {
        let viewModel = makeViewModel()
        await viewModel.start()
        viewModel.refresh()
        viewModel.stop()
        viewModel.refresh()
        viewModel.refresh()
        #expect(shortcutPrompt.openCount == 2)
    }

    @Test func shortcutPromptGetsReadinessFromScreen() {
        let viewModel = makeViewModel()
        viewModel.setControlsVisible(true)
        lighting.status = LightingStatus(faceLux: 400)
        viewModel.refreshStatus(now: 10)
        viewModel.refreshStatus(now: 13)
        #expect(shortcutPrompt.lastContext?.isControlsVisible == true)
        #expect(shortcutPrompt.lastContext?.faceSeenSeconds == 3)
        #expect(!viewModel.isShortcutPromptVisible)
    }

    @Test func shortcutPromptShowsOnceAndIsTracked() {
        let viewModel = makeViewModel()
        shortcutPrompt.shouldShowResult = true
        viewModel.refreshStatus(now: 0)
        viewModel.refreshStatus(now: 1)
        #expect(viewModel.isShortcutPromptVisible)
        #expect(shortcutPrompt.shownCount == 1)
        #expect(analytics.calls.filter { $0 == "shortcutPromptShown" }.count == 1)
    }

    @Test func hidingControlsHidesShortcutPrompt() {
        let viewModel = makeViewModel()
        shortcutPrompt.shouldShowResult = true
        viewModel.refreshStatus(now: 0)
        viewModel.setControlsVisible(false)
        #expect(!viewModel.isShortcutPromptVisible)
    }

    @Test func showMeHowOpensGuide() {
        let viewModel = makeViewModel()
        shortcutPrompt.shouldShowResult = true
        viewModel.refreshStatus(now: 0)
        viewModel.showShortcutGuide(fromPrompt: true)
        #expect(!viewModel.isShortcutPromptVisible)
        #expect(!viewModel.isShortcutGuideVisible)
        viewModel.shortcutPromptDidDisappear()
        #expect(viewModel.isShortcutGuideVisible)
        #expect(analytics.calls.contains("shortcutGuideOpened(true)"))
        viewModel.closeShortcutGuide()
        #expect(!viewModel.isShortcutGuideVisible)
    }

    @Test func statusBannerWaitsWhileShortcutPromptIsVisible() {
        let viewModel = makeViewModel()
        shortcutPrompt.shouldShowResult = true
        viewModel.refreshStatus(now: 0)
        shortcutPrompt.shouldShowResult = false
        viewModel.setLightMode(.on(.white))
        lighting.status = LightingStatus(faceLux: 100)
        viewModel.refreshStatus(now: 1)
        viewModel.refreshStatus(now: 4)
        #expect(viewModel.isShortcutPromptVisible)
        #expect(viewModel.status == nil)
        viewModel.snoozeShortcutPrompt()
        viewModel.refreshStatus(now: 5)
        viewModel.refreshStatus(now: 7)
        #expect(viewModel.status == .notEnoughLight)
    }

    @Test func cameraPauseClosesShortcutPrompt() {
        let viewModel = makeViewModel()
        shortcutPrompt.shouldShowResult = true
        viewModel.refreshStatus(now: 0)
        shortcutPrompt.shouldShowResult = false
        camera.state = .reconnecting
        viewModel.refreshStatus(now: 1)
        #expect(!viewModel.isShortcutPromptVisible)
        viewModel.refreshStatus(now: 3)
        #expect(viewModel.status == .cameraPaused)
    }

    @Test func settingsOpensGuideRightAway() {
        let viewModel = makeViewModel()
        viewModel.showShortcutGuide(fromPrompt: false)
        #expect(viewModel.isShortcutGuideVisible)
        #expect(analytics.calls.contains("shortcutGuideOpened(false)"))
    }

    @Test func notNowDoesNotOpenGuide() {
        let viewModel = makeViewModel()
        shortcutPrompt.shouldShowResult = true
        viewModel.refreshStatus(now: 0)
        viewModel.snoozeShortcutPrompt()
        viewModel.shortcutPromptDidDisappear()
        #expect(!viewModel.isShortcutGuideVisible)
    }

    @Test func dontShowAgainIsSaved() {
        let viewModel = makeViewModel()
        shortcutPrompt.shouldShowResult = true
        viewModel.refreshStatus(now: 0)
        viewModel.dismissShortcutPromptForever()
        #expect(!viewModel.isShortcutPromptVisible)
        #expect(shortcutPrompt.isDismissedForever)
        #expect(analytics.calls.contains("shortcutPromptDismissedForever"))
    }

    @Test func loadsSavedSettings() {
        settings.isLargerButtons = true
        settings.lightPlacement = .right
        let viewModel = makeViewModel()
        #expect(viewModel.isLargerButtons)
        #expect(viewModel.lightPlacement == .right)
    }

    @Test func changingSettingsSavesThem() {
        let viewModel = makeViewModel()
        viewModel.setLargerButtons(true)
        viewModel.setLightPlacement(.left)
        #expect(viewModel.isLargerButtons && settings.isLargerButtons)
        #expect(viewModel.lightPlacement == .left && settings.lightPlacement == .left)
    }

    @Test func glowFollowsLevel() {
        let viewModel = makeViewModel()
        viewModel.glowLevelDidChange(0.5)
        #expect(viewModel.glowOpacity == 0.5)
        #expect(viewModel.glowProgress > 0)
    }

    @Test func glowOffReturnsToFullCamera() {
        let viewModel = makeViewModel()
        viewModel.glowLevelDidChange(1)
        viewModel.glowLevelDidChange(0)
        #expect(viewModel.glowOpacity == 0)
        #expect(viewModel.glowProgress == 0)
    }

    @Test func faintAutoGlowKeepsFullCameraLook() {
        let viewModel = makeViewModel()
        viewModel.glowLevelDidChange(0.015)
        #expect(viewModel.glowProgress == 0)
    }

    @Test func lowLightStatusAppearsAndCanBeDismissed() {
        let viewModel = makeViewModel()
        viewModel.setLightMode(.on(.white))
        lighting.status = LightingStatus(faceLux: 100)
        viewModel.refreshStatus(now: 0)
        viewModel.refreshStatus(now: 2)
        #expect(viewModel.status == .notEnoughLight)
        viewModel.dismissStatus()
        viewModel.refreshStatus(now: 3)
        #expect(viewModel.status == nil)
    }

    @Test func reduceMotionIsForwardedToZoom() {
        let viewModel = makeViewModel()
        viewModel.setReduceMotion(true)
        #expect(zoom.reduceMotionValues == [true])
    }

    @Test func selectingPartUpdatesStateAndZoom() {
        let viewModel = makeViewModel()
        viewModel.select(.mouth)
        #expect(viewModel.selectedPart == .mouth)
        #expect(zoom.selectedParts == [.mouth])
    }

    @Test func settingLightModeForwardsToLighting() {
        let viewModel = makeViewModel()
        viewModel.setLightMode(.on(.warm))
        #expect(viewModel.lightMode == .on(.warm))
        #expect(lighting.lightModes == [.on(.warm)])
    }

    @Test func stopRestoresAutoLightAndStopsServices() {
        let viewModel = makeViewModel()
        viewModel.stop()
        #expect(lighting.autoCalls == [true])
        #expect(camera.stopCount == 1)
        #expect(zoom.stopCount == 1)
    }

    @Test func deniedCameraReportsDeniedPermission() {
        camera.state = .permissionDenied
        #expect(makeViewModel().permission == .denied)
    }

    @Test func cameraRunningAgainResetsZoomSession() {
        let viewModel = makeViewModel()
        viewModel.cameraStateDidChange(from: .reconnecting, to: .running)
        viewModel.cameraStateDidChange(from: .running, to: .running)
        #expect(zoom.resetCount == 1)
    }

    @Test func overallToggleIsForwardedToZoom() {
        let viewModel = makeViewModel()
        viewModel.setOverall(true)
        #expect(viewModel.isOverallOn)
        viewModel.setOverall(false)
        #expect(!viewModel.isOverallOn)
        #expect(zoom.overallValues == [true, false])
    }

    @Test func pickingAPartTurnsOverallOff() {
        let viewModel = makeViewModel()
        viewModel.setOverall(true)
        viewModel.select(.mouth)
        #expect(!viewModel.isOverallOn)
        #expect(zoom.overallValues == [true, false])
    }

    @Test func pausingStopsOnlyTheCamera() {
        let viewModel = makeViewModel()
        viewModel.pauseCamera()
        #expect(camera.stopCount == 1)
        #expect(zoom.stopCount == 0)
    }

    @Test func refreshCanSkipTheCamera() {
        let viewModel = makeViewModel()
        viewModel.refresh(startsCamera: false)
        #expect(camera.startCount == 0)
        viewModel.refresh()
        #expect(camera.startCount == 1)
    }
}
