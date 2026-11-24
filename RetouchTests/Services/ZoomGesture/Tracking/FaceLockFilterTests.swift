//
//  FaceLockFilterTests.swift
//  Retouch
//
//  Created by Retouch Team on 23/11/26.
//

import CoreGraphics
import Testing
@testable import Retouch

struct FaceLockFilterTests {
    private let step = 1.0 / 30
    private let zoom = ZoomTuning.fullFaceZoom
    private let center = CGPoint(x: 0.5, y: 0.5)

    @Test func waitsUntilFullFaceHasSettled() {
        var filter = FaceLockFilter()
        let pose = filter.update(active: true, detection: face(), flow: nil, canEngage: false, dt: step)
        #expect(pose == nil)
        #expect(!filter.isEngaged)
    }

    @Test func lockCentersTheFaceAtFullFaceZoom() throws {
        var filter = FaceLockFilter()
        let offCenter = CGPoint(x: 0.62, y: 0.41)
        let result = filter.update(active: true, detection: face(at: offCenter), flow: nil, canEngage: true, dt: step)
        let pose = try #require(result)
        #expect(pose.face == offCenter && pose.entry == offCenter)
        #expect(pose.anchor == CGPoint(x: ZoomTuning.faceLockAnchorX, y: ZoomTuning.faceLockAnchorY))
        #expect(pose.scale == ZoomTuning.fullFaceZoom && pose.anchorScale == ZoomTuning.fullFaceZoom)
        #expect(filter.isEngaged)
    }

    @Test func poseFollowsTheFaceWhileTheAnchorStays() throws {
        var filter = engaged()
        let pose = try #require(run(&filter, frames: 30) { _ in face(at: CGPoint(x: 0.6, y: 0.4)) })
        #expect(abs(pose.face.x - 0.6) < 0.001 && abs(pose.face.y - 0.4) < 0.001)
        #expect(pose.anchor == center)
    }

    @Test func flowCarriesTheFaceBetweenDetections() throws {
        var filter = engaged()
        let result = filter.update(active: true, detection: nil, flow: CGVector(dx: 0.03, dy: -0.01), canEngage: true, dt: step)
        let pose = try #require(result)
        #expect(abs(pose.face.x - 0.53) < 0.0001 && abs(pose.face.y - 0.49) < 0.0001)
    }

    @Test func movingFartherKeepsTheFaceSize() throws {
        var filter = engaged()
        let pose = try #require(run(&filter, frames: 60) { _ in face(width: 0.32) })
        let expected = ZoomTuning.faceLockFollowsDistance ? zoom * FaceLockFilter.softenedRatio(1.25) : zoom
        #expect(abs(pose.scale - expected) < 0.01)
        if ZoomTuning.faceLockFollowsDistance { #expect(pose.scale > zoom * 1.1) }
    }

    @Test func detectionNoiseDoesNotPulseTheFaceSize() throws {
        var filter = engaged()
        let widths: [CGFloat] = [0.4, 0.388, 0.412, 0.39, 0.41, 0.392]
        for frame in 0..<90 {
            let result = filter.update(active: true, detection: face(width: widths[frame % widths.count]),
                                       flow: nil, canEngage: true, dt: step)
            let pose = try #require(result)
            #expect(pose.scale == zoom)
        }
    }

    @Test func slightlyCloserKeepsTheFrameFull() throws {
        var filter = engaged()
        let pose = try #require(run(&filter, frames: 60) { _ in face(width: 0.46) })
        #expect(abs(pose.scale - zoom) < 0.0001)
    }

    @Test func closerOnlyShrinksPastTheDeadZone() {
        #expect(FaceLockFilter.softenedRatio(1) == 1)
        #expect(FaceLockFilter.softenedRatio(1 - ZoomTuning.faceLockCloseDeadZone) == 1)
        #expect(abs(FaceLockFilter.softenedRatio(0.6) - 0.85) < 0.0001)
        #expect(FaceLockFilter.softenedRatio(0.5) < FaceLockFilter.softenedRatio(0.6))
    }

    @Test func fartherOnlyGrowsPastTheDeadZone() {
        let deadZone = ZoomTuning.faceLockFarDeadZone
        let ramp = ZoomTuning.faceLockFarRamp
        #expect(FaceLockFilter.softenedRatio(1 + deadZone) == 1)
        #expect(FaceLockFilter.softenedRatio(1.03) == 1)
        #expect(abs(FaceLockFilter.softenedRatio(1 + deadZone + ramp) - (1 + ramp / 2)) < 0.0001)
        #expect(abs(FaceLockFilter.softenedRatio(1.5) - (1.5 - deadZone - ramp / 2)) < 0.0001)
        #expect(FaceLockFilter.softenedRatio(1.4) > FaceLockFilter.softenedRatio(1.3))
    }

    @Test func sizeCorrectionIsLimited() throws {
        var filter = engaged()
        let pose = try #require(run(&filter, frames: 90) { _ in face(width: 0.05) })
        let expected = ZoomTuning.faceLockFollowsDistance ? zoom * ZoomTuning.faceLockMaxSizeRatio : zoom
        #expect(abs(pose.scale - expected) < 0.001)
    }

    @Test func fixedScaleIgnoresDistanceWhenSwitchedOff() throws {
        var filter = engaged()
        let closer = try #require(run(&filter, frames: 60) { _ in face(width: 0.8) })
        let farther = try #require(run(&filter, frames: 60) { _ in face(width: 0.2) })
        if !ZoomTuning.faceLockFollowsDistance {
            #expect(closer.scale == zoom)
            #expect(farther.scale == zoom)
        }
    }

    @Test func leavingFullFaceReleasesTheLock() {
        var filter = engaged()
        var pose: FaceLockPose? = nil
        for _ in 0..<75 {
            pose = filter.update(active: false, detection: nil, flow: nil, canEngage: false, dt: step)
        }
        #expect(pose == nil)
        #expect(!filter.isEngaged)
    }

    @Test func lostFaceHoldsThenReleases() {
        var filter = engaged()
        _ = run(&filter, frames: 30) { _ in face() }
        let held = run(&filter, frames: 30) { _ in nil }
        #expect((held?.weight ?? 0) > 0.9)
        let gone = run(&filter, frames: 120) { _ in nil }
        #expect(gone == nil)
        #expect(!filter.isEngaged)
    }

    @Test func lockedPlacementPutsTheFaceOnItsAnchor() {
        let extent = CGRect(x: 0, y: 0, width: 1440, height: 1920)
        let size = CGSize(width: 1179, height: 2556)
        let fill = max(size.width / extent.width, size.height / extent.height)
        let pose = FaceLockPose(face: CGPoint(x: 0.62, y: 0.41), entry: CGPoint(x: 0.5, y: 0.55),
                                anchor: CGPoint(x: 0.5, y: 0.55), anchorScale: zoom, scale: zoom * 1.3, weight: 1)
        let placed = MirrorRenderer.lockedPlacement(pose, extent: extent, fill: fill, size: size)
        let faceOnScreen = CGPoint(x: placed.origin.x + (pose.face.x - 0.5) * extent.width * placed.total,
                                   y: placed.origin.y + (pose.face.y - 0.5) * extent.height * placed.total)
        let anchorOnScreen = CGPoint(x: size.width / 2 + (pose.anchor.x - 0.5) * extent.width * fill * zoom,
                                     y: size.height / 2 + (pose.anchor.y - 0.5) * extent.height * fill * zoom)
        #expect(abs(faceOnScreen.x - anchorOnScreen.x) < 0.001)
        #expect(abs(faceOnScreen.y - anchorOnScreen.y) < 0.001)
        #expect(abs(placed.total - fill * zoom * 1.3) < 0.0001)
    }

    @Test func faceSittingHighIsCenteredAsConfigured() {
        let extent = CGRect(x: 0, y: 0, width: 1440, height: 1920)
        let size = CGSize(width: 1179, height: 2556)
        let fill = max(size.width / extent.width, size.height / extent.height)
        let pose = FaceLockPose(face: CGPoint(x: 0.5, y: 0.3), entry: CGPoint(x: 0.5, y: 0.3),
                                anchor: CGPoint(x: 0.5, y: 0.5), anchorScale: zoom, scale: zoom, weight: 1)
        let placed = MirrorRenderer.lockedPlacement(pose, extent: extent, fill: fill, size: size)
        let roomY = 0.5 * (1 - size.height / (extent.height * fill * zoom))
        let target = ZoomTuning.faceLockCentersFully ? 0.5 : 0.3 + roomY * ZoomTuning.faceLockCenterRoomUseY
        let faceY = placed.origin.y + (pose.face.y - 0.5) * extent.height * placed.total
        let expected = size.height / 2 + (target - 0.5) * extent.height * fill * zoom
        #expect(abs(faceY - expected) < 0.001)
    }

    @Test func lateDetectionIsShiftedByTheMotionSinceItsFrame() {
        let found = FaceLockFilter.Detection(center: CGPoint(x: 0.6, y: 0.5), width: 0.4)
        let shifted = FaceLockStabilizer.compensated(found, then: CGPoint(x: 0.55, y: 0.48),
                                                     now: CGPoint(x: 0.58, y: 0.47))
        #expect(abs(shifted.center.x - 0.63) < 0.0001)
        #expect(abs(shifted.center.y - 0.49) < 0.0001)
        #expect(shifted.width == 0.4)
    }

    @Test func rollStartsFromTheCurrentTilt() throws {
        var filter = FaceLockFilter()
        let pose = try #require(filter.update(active: true, detection: tilted(0.2), flow: nil,
                                              canEngage: true, dt: step))
        #expect(abs(pose.roll - 0.2) < 0.0001)
    }

    @Test func rollFollowsTheHead() throws {
        var filter = engaged()
        let pose = try #require(run(&filter, frames: 90) { _ in tilted(0.3) })
        #expect(abs(pose.roll - 0.3) < 0.001)
    }

    @Test func rollCatchesUpWithoutLag() throws {
        var filter = FaceLockFilter()
        _ = filter.update(active: true, detection: tilted(0), flow: nil, canEngage: true, dt: step)
        let pose = try #require(run(&filter, frames: 15) { _ in tilted(0.3) })
        #expect(abs(pose.roll - 0.3) < 0.01)
    }

    @Test func faceSizeStaysStillAfterMovingFarther() throws {
        var filter = engaged()
        _ = run(&filter, frames: 60) { _ in face(width: 0.3) }
        let noise: [CGFloat] = [0.3, 0.294, 0.306, 0.296, 0.304, 0.298]
        _ = run(&filter, frames: 30) { frame in face(width: noise[frame % noise.count]) }
        var scales: [CGFloat] = []
        for frame in 0..<60 {
            let result = filter.update(active: true, detection: face(width: noise[frame % noise.count]),
                                       flow: nil, canEngage: true, dt: step)
            scales.append(try #require(result).scale)
        }
        let spread = (scales.max() ?? 0) - (scales.min() ?? 0)
        #expect(spread < 0.002)
    }

    @Test func tiltJitterIsDamped() throws {
        var filter = FaceLockFilter()
        _ = filter.update(active: true, detection: tilted(0), flow: nil, canEngage: true, dt: step)
        for frame in 0..<90 {
            let result = filter.update(active: true, detection: tilted(frame % 2 == 0 ? 0.03 : -0.03),
                                       flow: nil, canEngage: true, dt: step)
            let pose = try #require(result)
            #expect(abs(pose.roll) < 0.004)
        }
    }

    @Test func rollIsLimited() throws {
        var filter = engaged()
        let pose = try #require(run(&filter, frames: 30) { _ in tilted(1.4) })
        #expect(pose.roll <= ZoomTuning.faceLockMaxRoll + 0.0001)
    }

    @Test func lockedTransformKeepsTheEyesLevel() {
        let extent = CGRect(x: 0, y: 0, width: 1440, height: 1920)
        let size = CGSize(width: 1179, height: 2556)
        let fill = max(size.width / extent.width, size.height / extent.height)
        let pose = FaceLockPose(face: CGPoint(x: 0.6, y: 0.45), entry: CGPoint(x: 0.6, y: 0.45),
                                anchor: CGPoint(x: 0.5, y: 0.5), anchorScale: zoom, scale: zoom,
                                weight: 1, roll: 0.25)
        let placement = MirrorRenderer.lockedTransform(pose, extent: extent, fill: fill, size: size,
                                                       normalOrigin: CGPoint(x: size.width / 2, y: size.height / 2),
                                                       normalTotal: fill * zoom)
        let face = CGPoint(x: 0.6 * extent.width, y: 0.45 * extent.height)
        let eye = CGPoint(x: face.x + 100 * cos(0.25), y: face.y + 100 * sin(0.25))
        let a = face.applying(placement.transform)
        let b = eye.applying(placement.transform)
        let anchor = MirrorRenderer.lockedPlacement(pose, extent: extent, fill: fill, size: size)
        let expected = CGPoint(x: anchor.origin.x + 0.1 * extent.width * anchor.total,
                               y: anchor.origin.y - 0.05 * extent.height * anchor.total)
        #expect(abs(b.y - a.y) < 0.001)
        #expect(abs(a.x - expected.x) < 0.001 && abs(a.y - expected.y) < 0.001)
    }

    @Test func eyeLineAngleIgnoresEyeOrder() {
        let left = [CGPoint(x: 100, y: 100), CGPoint(x: 110, y: 102)]
        let right = [CGPoint(x: 200, y: 120), CGPoint(x: 210, y: 122)]
        let forward = FaceLockDetector.eyeRoll(left, right)
        let backward = FaceLockDetector.eyeRoll(right, left)
        #expect(forward != nil && forward == backward)
        #expect(abs((forward ?? 0) - atan2(20, 100)) < 0.0001)
    }

        @Test func regionCoversTheFaceInBufferSpace() {
        let region = FaceLockStabilizer.region(around: CGPoint(x: 0.5, y: 0.8), width: 0.4,
                                               bufferWidth: 1280, bufferHeight: 960)
        #expect(abs(region.midX - 0.2) < 0.0001)
        #expect(abs(region.midY - 0.5) < 0.0001)
        #expect(abs(region.height - 0.4 * ZoomTuning.faceLockRegionScale) < 0.0001)
    }

    private func engaged() -> FaceLockFilter {
        var filter = FaceLockFilter()
        _ = filter.update(active: true, detection: face(), flow: nil, canEngage: true, dt: step)
        return filter
    }

    private func tilted(_ roll: CGFloat) -> FaceLockFilter.Detection {
        FaceLockFilter.Detection(center: CGPoint(x: 0.5, y: 0.5), width: 0.4, roll: roll)
    }

    private func face(at point: CGPoint = CGPoint(x: 0.5, y: 0.5), width: CGFloat = 0.4) -> FaceLockFilter.Detection {
        FaceLockFilter.Detection(center: point, width: width)
    }

    private func run(_ filter: inout FaceLockFilter, frames: Int,
                     detection: (Int) -> FaceLockFilter.Detection?) -> FaceLockPose? {
        var pose: FaceLockPose?
        for frame in 0..<frames {
            pose = filter.update(active: true, detection: detection(frame), flow: nil, canEngage: true,
                                 dt: step)
        }
        return pose
    }
}
