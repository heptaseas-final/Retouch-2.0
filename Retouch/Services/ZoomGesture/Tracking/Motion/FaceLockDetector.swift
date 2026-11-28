//
//  FaceLockDetector.swift
//  Retouch
//
//  Created by Retouch Team on 24/11/26.
//

import CoreGraphics
import CoreVideo
import Foundation
import Vision

nonisolated final class FaceLockDetector: @unchecked Sendable {
    struct Result {
        var detection: FaceLockFilter.Detection?
        var time: Double
    }

    private let queue = DispatchQueue(label: "retouch.facelock.detect", qos: .userInitiated)
    private let request = VNDetectFaceLandmarksRequest()
    private let lock = NSLock()
    private var isBusy = false
    private var generation = 0
    private var pending: Result?

    func submit(_ buffer: CVPixelBuffer, time: Double, target: FaceLockFilter.Detection?) {
        let ticket: Int? = lock.withLock {
            guard !isBusy else { return nil }
            isBusy = true
            return generation
        }
        guard let ticket else { return }
        queue.async { [self] in
            let detection = detect(buffer, following: target)
            lock.withLock {
                isBusy = false
                if ticket == generation { pending = Result(detection: detection, time: time) }
            }
        }
    }

    private func detect(_ buffer: CVPixelBuffer, following target: FaceLockFilter.Detection?) -> FaceLockFilter.Detection? {
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .leftMirrored)
        try? handler.perform([request])
        let size = CGSize(width: CVPixelBufferGetHeight(buffer), height: CVPixelBufferGetWidth(buffer))
        let faces = (request.results ?? []).map { face -> FaceLockFilter.Detection in
            let box = face.boundingBox
            let left = face.landmarks?.leftEye?.pointsInImage(imageSize: size) ?? []
            let right = face.landmarks?.rightEye?.pointsInImage(imageSize: size) ?? []
            let roll = Self.eyeRoll(left, right) ?? face.roll.map { CGFloat($0.doubleValue) }
            return FaceLockFilter.Detection(center: CGPoint(x: box.midX, y: box.midY), width: box.width, roll: roll)
        }
        return Self.choose(faces, following: target)
    }

    static func choose(_ faces: [FaceLockFilter.Detection],
                       following target: FaceLockFilter.Detection?) -> FaceLockFilter.Detection? {
        guard let target else { return faces.max { $0.width < $1.width } }
        let reach = target.width * ZoomTuning.faceLockMatchRadius
        return faces
            .map { (face: $0, gap: hypot($0.center.x - target.center.x, $0.center.y - target.center.y)) }
            .filter { $0.gap <= reach }
            .min { $0.gap < $1.gap }?
            .face
    }

    func take() -> Result? {
        lock.withLock {
            defer { pending = nil }
            return pending
        }
    }

    func reset() {
        lock.withLock {
            generation += 1
            pending = nil
        }
    }

    static func eyeRoll(_ first: [CGPoint], _ second: [CGPoint]) -> CGFloat? {
        guard !first.isEmpty, !second.isEmpty else { return nil }
        let a = centroid(first)
        let b = centroid(second)
        let (start, end) = a.x <= b.x ? (a, b) : (b, a)
        return atan2(end.y - start.y, end.x - start.x)
    }

    private static func centroid(_ points: [CGPoint]) -> CGPoint {
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
}
