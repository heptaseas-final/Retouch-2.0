//
//  FaceLockStabilizer.swift
//  Retouch
//
//  Created by Retouch Team on 23/11/26.
//

import CoreGraphics
import CoreVideo
import Foundation

nonisolated final class FaceLockStabilizer {
    private let tracker = FrameMotionTracker()
    private let detector = FaceLockDetector()
    private var filter = FaceLockFilter()
    private var lastTime: Double?
    private var history: [(time: Double, position: CGPoint)] = []

    var isEngaged: Bool { filter.isEngaged }

    func update(_ buffer: CVPixelBuffer, time: Double, isActive: Bool, canEngage: Bool) -> FaceLockPose? {
        let dt = lastTime.map { time - $0 } ?? 0
        let isLandscape = CVPixelBufferGetWidth(buffer) > CVPixelBufferGetHeight(buffer)
        let active = isActive && isLandscape
        var detection: FaceLockFilter.Detection?
        var flow: CGVector?
        if active {
            let target = filter.position.map { FaceLockFilter.Detection(center: $0, width: filter.width) }
            detector.submit(buffer, time: time, target: target)
            flow = measureFlow(buffer)
            if let result = detector.take(), let found = result.detection {
                detection = latest(found, detectedAt: result.time, flow: flow)
            }
        } else {
            tracker.reset()
            detector.reset()
            history.removeAll()
        }
        let pose = filter.update(active: active, detection: detection, flow: flow, canEngage: canEngage, dt: dt)
        if let position = filter.position {
            history.append((time, position))
            if history.count > ZoomTuning.faceLockHistoryFrames { history.removeFirst() }
        } else {
            history.removeAll()
        }
        lastTime = active || filter.isEngaged ? time : nil
        return pose
    }

    static func compensated(_ found: FaceLockFilter.Detection, then: CGPoint,
                            now: CGPoint) -> FaceLockFilter.Detection {
        FaceLockFilter.Detection(center: CGPoint(x: now.x + found.center.x - then.x,
                                                 y: now.y + found.center.y - then.y),
                                 width: found.width, roll: found.roll)
    }

    private func latest(_ found: FaceLockFilter.Detection, detectedAt time: Double,
                        flow: CGVector?) -> FaceLockFilter.Detection {
        guard let current = filter.position,
              let then = history.last(where: { $0.time <= time })?.position else { return found }
        let now = CGPoint(x: current.x + (flow?.dx ?? 0), y: current.y + (flow?.dy ?? 0))
        return Self.compensated(found, then: then, now: now)
    }

    private func measureFlow(_ buffer: CVPixelBuffer) -> CGVector? {
        guard let face = filter.position, filter.width > 0 else {
            tracker.reset()
            return nil
        }
        let region = Self.region(around: face, width: filter.width,
                                 bufferWidth: CGFloat(CVPixelBufferGetWidth(buffer)),
                                 bufferHeight: CGFloat(CVPixelBufferGetHeight(buffer)))
        guard let shift = tracker.regionShift(buffer, region: region) else { return nil }
        return CGVector(dx: shift.y, dy: -shift.x)
    }

    static func region(around face: CGPoint, width: CGFloat, bufferWidth: CGFloat, bufferHeight: CGFloat) -> CGRect {
        let scale = ZoomTuning.faceLockRegionScale
        let halfColumns = 0.5 * width * scale * bufferHeight / max(bufferWidth, 1)
        let halfRows = 0.5 * width * scale
        let column = 1 - face.y
        let row = face.x
        let rect = CGRect(x: column - halfColumns, y: row - halfRows, width: 2 * halfColumns, height: 2 * halfRows)
        return rect.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
    }
}
