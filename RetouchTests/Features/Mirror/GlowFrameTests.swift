import SwiftUI
import Testing
@testable import Retouch

@MainActor
struct GlowFrameTests {
    private let phone = CGSize(width: 393, height: 852)
    private let tolerance: CGFloat = 0.000_1

    private func isClose(_ value: CGFloat, _ expected: CGFloat) -> Bool {
        abs(value - expected) < tolerance
    }

    @Test func faintLevelShowsNoFrame() {
        #expect(GlowFrame.glowProgress(level: 0.015) == 0)
        let hole = GlowFrame.holeScale(in: phone, progress: 0, isOverall: false)
        #expect(hole == CGSize(width: 1, height: 1))
    }

    @Test func fullGlowMatchesTheOverallFrame() {
        let progress = GlowFrame.glowProgress(level: 1)
        let normal = GlowFrame.holeScale(in: phone, progress: progress, isOverall: false)
        let overall = GlowFrame.holeScale(in: phone, progress: 0.3, isOverall: true)
        #expect(isClose(normal.width, overall.width))
        #expect(isClose(normal.height, overall.height))
    }

    @Test func overallFrameHasThinSidesAndFullBands() {
        let hole = GlowFrame.holeScale(in: phone, progress: 0, isOverall: true)
        #expect(isClose(hole.width * 393, 393 - 2 * GlowFrame.sideLightWidth))
        #expect(isClose(hole.height * 852, 524))
    }

    @Test func frameClosesInSmoothlyWithLevel() {
        let low = GlowFrame.holeScale(in: phone, progress: GlowFrame.glowProgress(level: 0.3), isOverall: false)
        let high = GlowFrame.holeScale(in: phone, progress: GlowFrame.glowProgress(level: 0.7), isOverall: false)
        #expect(low.height > high.height)
        #expect(low.height < 1)
    }

    @Test func progressIsClamped() {
        #expect(GlowFrame.holeScale(in: phone, progress: 3, isOverall: false)
                == GlowFrame.holeScale(in: phone, progress: 1, isOverall: false))
        #expect(GlowFrame.holeScale(in: phone, progress: -1, isOverall: false) == CGSize(width: 1, height: 1))
    }

    @Test func zeroSizeShowsNoFrame() {
        #expect(GlowFrame.holeScale(in: .zero, progress: 1, isOverall: true) == CGSize(width: 1, height: 1))
    }

    @Test(arguments: [CGSize(width: 393, height: 852), CGSize(width: 440, height: 956), CGSize(width: 375, height: 667)])
    func clearAreaIsAtLeastHalfTheScreen(screen: CGSize) {
        let hole = GlowFrame.holeScale(in: screen, progress: 1, isOverall: false)
        #expect(hole.width * hole.height >= 0.5)
    }

    @Test func noGlowKeepsCameraZoomAsIs() {
        #expect(GlowFrame.zoomShrink(in: phone, progress: 0, isOverall: false) == 1)
    }

    @Test func overallModeIsNotShrunkTwice() {
        #expect(GlowFrame.zoomShrink(in: phone, progress: 1, isOverall: true) == 1)
    }

    @Test func fullGlowFitsCameraIntoOverallFrame() {
        #expect(isClose(GlowFrame.zoomShrink(in: phone, progress: 1, isOverall: false), 524.0 / 852.0))
    }

    @Test(arguments: [CGFloat(0.2), 0.5, 0.8])
    func pictureEdgeMeetsLightEdge(progress: CGFloat) {
        let shrink = GlowFrame.zoomShrink(in: phone, progress: progress, isOverall: false)
        let hole = GlowFrame.holeScale(in: phone, progress: progress, isOverall: false)
        #expect(isClose(shrink, hole.height))
    }

    @Test func fullFaceShrinksIntoTheOverallFrame() {
        let zoom = ZoomState(scale: ZoomTuning.fullFaceZoom, offset: CGSize(width: 40, height: -20))
        let windowed = GlowFrame.windowedZoom(zoom, shrink: 0.5)
        #expect(isClose(windowed.scale, ZoomTuning.fullFaceZoom * 0.5))
        #expect(windowed.offset == CGSize(width: 20, height: -10))
    }

    @Test(arguments: [ZoomTuning.sideZoom, ZoomTuning.noseZoomScale, ZoomTuning.lipsZoomScale, ZoomTuning.eyeZoomScale])
    func detailZoomKeepsItsCompositionInsideTheFrame(scale: CGFloat) {
        let shrink = GlowFrame.zoomShrink(in: phone, progress: 1, isOverall: false)
        let zoom = ZoomState(scale: scale, offset: CGSize(width: 40, height: -20))
        let windowed = GlowFrame.windowedZoom(zoom, shrink: shrink)
        #expect(isClose(windowed.scale / scale, shrink))
        #expect(isClose(windowed.offset.width / 40, shrink))
        #expect(isClose(windowed.offset.height / -20, shrink))
    }

    @Test func zoomAreaEdgesLandOnTheFrameEdges() {
        let shrink = GlowFrame.zoomShrink(in: phone, progress: 1, isOverall: false)
        let window = GlowFrame.windowRect(in: phone)
        #expect(isClose(phone.height / 2 * shrink, window.height / 2))
        #expect(phone.width / 2 * shrink <= window.width / 2 - GlowFrame.sideLightWidth)
    }

    @Test func zoomingInNeverLooksLikeZoomingOut() {
        let shrink: CGFloat = 524.0 / 852.0
        var previous: CGFloat = 0
        for step in 0...240 {
            let scale = 0.6 + CGFloat(step) * 0.01
            let shown = GlowFrame.windowedZoom(ZoomState(scale: scale), shrink: shrink).scale
            #expect(shown >= previous)
            previous = shown
        }
    }

    @Test func reduceMotionFadeShrinksTheSameWay() {
        let fade = ZoomFade(fromScale: ZoomTuning.fullFaceZoom, fromOffset: CGSize(width: 10, height: 0), progress: 0.3)
        let zoom = ZoomState(scale: ZoomTuning.eyeZoomScale, offset: .zero, fade: fade)
        let windowed = GlowFrame.windowedZoom(zoom, shrink: 0.5)
        #expect(isClose(windowed.scale, ZoomTuning.eyeZoomScale * 0.5))
        #expect(isClose(windowed.fade?.fromScale ?? 0, ZoomTuning.fullFaceZoom * 0.5))
        #expect(windowed.fade?.fromOffset == CGSize(width: 5, height: 0))
        #expect(windowed.fade?.progress == 0.3)
    }

    @Test func holeShapeLeavesTheFrameClear() {
        let screen = CGRect(origin: .zero, size: phone)
        let hole = GlowFrame.holeScale(in: phone, progress: 1, isOverall: false)
        let path = GlowHoleShape(holeScale: hole).path(in: screen)
        #expect(!path.contains(CGPoint(x: 196, y: 426), eoFill: true))
        #expect(path.contains(CGPoint(x: 196, y: 40), eoFill: true))
        #expect(path.contains(CGPoint(x: 10, y: 426), eoFill: true))
    }

    @Test func noShrinkLeavesZoomUntouched() {
        let zoom = ZoomState(scale: 1.9, offset: CGSize(width: 3, height: 4))
        #expect(GlowFrame.windowedZoom(zoom, shrink: 1) == zoom)
    }

    @Test func windowMatchesOverallFrameOnTallScreen() {
        let window = GlowFrame.windowRect(in: phone)
        #expect(isClose(window.width, 393))
        #expect(isClose(window.height, 524))
        #expect(isClose(window.minY, 164))
    }

    @Test func windowFitsHeightOnWideSize() {
        let window = GlowFrame.windowRect(in: CGSize(width: 600, height: 400))
        #expect(isClose(window.width, 300))
        #expect(isClose(window.minX, 150))
    }

    @Test func darkToMaxRiseTakesFullRiseDuration() {
        #expect(GlowFrame.rampDuration(from: 0, to: 1) == GlowFrame.fullRiseDuration)
    }

    @Test func maxToDarkFallTakesFullFallDuration() {
        #expect(GlowFrame.rampDuration(from: 1, to: 0) == GlowFrame.fullFallDuration)
    }

    @Test func smallAutoStepStillBlendsSmoothly() {
        #expect(GlowFrame.rampDuration(from: 0.4, to: 0.41) == GlowFrame.minimumRampDuration)
    }

    @Test func rampClampsLevels() {
        #expect(GlowFrame.rampDuration(from: -1, to: 2) == GlowFrame.fullRiseDuration)
    }
}
