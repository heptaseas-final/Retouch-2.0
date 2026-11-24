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
        let expected = ZoomTuning.faceLockFollowsDistance ? zoom * 1.25 : zoom
        #expect(abs(pose.scale - expected) < 0.01)
    }

    @Test func slightlyCloserKeepsTheFrameFull() throws {
        var filter = engaged()
        let pose = try #require(run(&filter, frames: 60) { _ in face(width: 0.46) })
        #expect(abs(pose.scale - zoom) < 0.0001)
    }

    @Test func closerOnlyShrinksPastTheDeadZone() {
        #expect(FaceLockFilter.softenedCloser(1.3) == 1.3)
        #expect(FaceLockFilter.softenedCloser(1) == 1)
        #expect(FaceLockFilter.softenedCloser(1 - ZoomTuning.faceLockCloseDeadZone) == 1)
        #expect(abs(FaceLockFilter.softenedCloser(0.6) - 0.85) < 0.0001)
        #expect(FaceLockFilter.softenedCloser(0.5) < FaceLockFilter.softenedCloser(0.6))
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
