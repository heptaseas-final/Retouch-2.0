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

    func submit(_ buffer: CVPixelBuffer, time: Double) {
        let ticket: Int? = lock.withLock {
            guard !isBusy else { return nil }
            isBusy = true
            return generation
        }
        guard let ticket else { return }
        queue.async { [self] in
            let detection = detect(buffer)
            lock.withLock {
                isBusy = false
                if ticket == generation { pending = Result(detection: detection, time: time) }
            }
        }
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

    private func detect(_ buffer: CVPixelBuffer) -> FaceLockFilter.Detection? {
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .leftMirrored)
        try? handler.perform([request])
        guard let face = request.results?.max(by: { $0.boundingBox.height < $1.boundingBox.height }) else {
            return nil
        }
        let box = face.boundingBox
        let size = CGSize(width: CVPixelBufferGetHeight(buffer), height: CVPixelBufferGetWidth(buffer))
        let left = face.landmarks?.leftEye?.pointsInImage(imageSize: size) ?? []
        let right = face.landmarks?.rightEye?.pointsInImage(imageSize: size) ?? []
        let roll = Self.eyeRoll(left, right) ?? face.roll.map { CGFloat($0.doubleValue) }
        return FaceLockFilter.Detection(center: CGPoint(x: box.midX, y: box.midY), width: box.width, roll: roll)
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
