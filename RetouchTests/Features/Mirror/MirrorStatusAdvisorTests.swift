import Testing
@testable import Retouch

struct MirrorStatusAdvisorTests {
    private let dark = MirrorStatusInput(faceLux: 120, isLightAtLimit: true, faceWidthRatio: 0.7)
    private let bright = MirrorStatusInput(faceLux: 400, faceWidthRatio: 0.7)

    @Test func lowLightNeedsToLastBeforeShowing() {
        var advisor = MirrorStatusAdvisor()
        let first = advisor.update(dark, now: 0)
        let later = advisor.update(dark, now: 1.6)
        #expect(first == nil)
        #expect(later == .notEnoughLight)
    }

    @Test func lowLightWaitsForGlowAtMax() {
        var advisor = MirrorStatusAdvisor()
        var input = dark
        input.isLightAtLimit = false
        _ = advisor.update(input, now: 0)
        let status = advisor.update(input, now: 2)
        #expect(status == nil)
    }

    @Test func enoughLightShowsForTwoSecondsAfterLowLight() {
        var advisor = MirrorStatusAdvisor()
        _ = advisor.update(dark, now: 0)
        _ = advisor.update(dark, now: 1.6)
        _ = advisor.update(bright, now: 2)
        let shown = advisor.update(bright, now: 6.2)
        let stillShown = advisor.update(bright, now: 8.1)
        let gone = advisor.update(bright, now: 8.3)
        #expect(shown == .enoughLight)
        #expect(stillShown == .enoughLight)
        #expect(gone == nil)
    }

    @Test func errorMessageHidesAfterItsDisplayTime() {
        var advisor = MirrorStatusAdvisor()
        _ = advisor.update(dark, now: 0)
        let shown = advisor.update(dark, now: 1.6)
        let stillShown = advisor.update(dark, now: 1.6 + MirrorStatusConfig.errorTime - 0.1)
        let gone = advisor.update(dark, now: 1.6 + MirrorStatusConfig.errorTime + 0.1)
        #expect(shown == .notEnoughLight)
        #expect(stillShown == .notEnoughLight)
        #expect(gone == nil)
    }

    @Test func enoughLightNeedsLowLightFirst() {
        var advisor = MirrorStatusAdvisor()
        _ = advisor.update(bright, now: 0)
        let status = advisor.update(bright, now: 2)
        #expect(status == nil)
    }

    @Test func dismissedMessageDoesNotComeBack() {
        var advisor = MirrorStatusAdvisor()
        _ = advisor.update(dark, now: 0)
        _ = advisor.update(dark, now: 1.6)
        advisor.dismiss()
        _ = advisor.update(bright, now: 2)
        _ = advisor.update(dark, now: 3)
        let status = advisor.update(dark, now: 5)
        #expect(status != .notEnoughLight)
    }

    @Test func cameraPausedWinsAndShowsRightAway() {
        var advisor = MirrorStatusAdvisor()
        var input = dark
        input.isCameraPaused = true
        let status = advisor.update(input, now: 0)
        #expect(status == .cameraPaused)
    }

    @Test func tooFarOnlyWhenZoomedIn() {
        var advisor = MirrorStatusAdvisor()
        var input = MirrorStatusInput(faceLux: 400, faceWidthRatio: 0.2, zoomScale: 1)
        _ = advisor.update(input, now: 0)
        let unzoomed = advisor.update(input, now: 2)
        input.zoomScale = 2.25
        _ = advisor.update(input, now: 3)
        let zoomed = advisor.update(input, now: 4.6)
        #expect(unzoomed == nil)
        #expect(zoomed == .tooFar)
    }

    @Test func faceTooWideShowsOnceForThreeSeconds() {
        var advisor = MirrorStatusAdvisor()
        let input = MirrorStatusInput(faceLux: 400, faceWidthRatio: 1.2, zoomScale: 1)
        _ = advisor.update(input, now: 0)
        let shown = advisor.update(input, now: 1.6)
        let gone = advisor.update(input, now: 4.7)
        #expect(shown == .faceTooWide)
        #expect(gone == nil)
    }
    
    @Test func moveCloserHiddenInOverall() {
        var advisor = MirrorStatusAdvisor()
        var input = MirrorStatusInput(faceLux: 120, faceWidthRatio: 0.3)
        input.isOverall = true
        _ = advisor.update(input, now: 0)
        let status = advisor.update(input, now: 2)
        #expect(status == nil)
    }

    @Test func moveCloserShowsOutsideOverall() {
        var advisor = MirrorStatusAdvisor()
        let input = MirrorStatusInput(faceLux: 120, faceWidthRatio: 0.3)
        _ = advisor.update(input, now: 0)
        let status = advisor.update(input, now: 2)
        #expect(status == .moveCloserInLowLight)
    }
    
    @Test func moveCloserDisappearsAtOnceWhenOverallStarts() {
        var advisor = MirrorStatusAdvisor()
        var input = MirrorStatusInput(faceLux: 120, faceWidthRatio: 0.3)
        _ = advisor.update(input, now: 0)
        let shown = advisor.update(input, now: 1.6)
        input.isOverall = true
        let gone = advisor.update(input, now: 1.8)
        #expect(shown == .moveCloserInLowLight)
        #expect(gone == nil)
    }
}
