//
//  FaceLockStabilizer.swift
//  Retouch
//
//  Created by Retouch Team on 23/11/26.
//

import CoreGraphics
import CoreVideo
import Foundation
import Vision

nonisolated final class FaceLockStabilizer {
    private let tracker = FrameMotionTracker()
    private let request = VNDetectFaceRectanglesRequest()
    private var filter = FaceLockFilter()
    private var lastTime: Double?
    private var frameCount = 0

    var isEngaged: Bool { filter.isEngaged }

    func update(_ buffer: CVPixelBuffer, time: Double, isActive: Bool, canEngage: Bool) -> FaceLockPose? {
        let dt = lastTime.map { time - $0 } ?? 0
        let isLandscape = CVPixelBufferGetWidth(buffer) > CVPixelBufferGetHeight(buffer)
        let active = isActive && isLandscape
        var detection: FaceLockFilter.Detection?
        var flow: CGVector?
        if active {
            frameCount += 1
            if frameCount % max(ZoomTuning.faceLockDetectInterval, 1) == 0 { detection = detect(buffer) }
            flow = measureFlow(buffer)
        } else {
            tracker.reset()
            frameCount = 0
        }
        let pose = filter.update(active: active, detection: detection, flow: flow, canEngage: canEngage, dt: dt)
        lastTime = active || filter.isEngaged ? time : nil
        return pose
    }

    private func detect(_ buffer: CVPixelBuffer) -> FaceLockFilter.Detection? {
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .leftMirrored)
        try? handler.perform([request])
        guard let face = request.results?.max(by: { $0.boundingBox.height < $1.boundingBox.height }) else {
            return nil
        }
        let box = face.boundingBox
        return FaceLockFilter.Detection(center: CGPoint(x: box.midX, y: box.midY), width: box.width)
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
