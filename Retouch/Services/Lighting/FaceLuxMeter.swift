//
//  FaceLuxMeter.swift
//  Retouch
//
//  Created by Davin P on 09/11/26.
//

import CoreVideo
import Vision

nonisolated final class FaceLuxMeter: @unchecked Sendable {
    struct Result {
        var areaLuma: [Float?]
        var redness: Float?
        var faceHeight: Float?
        var exposureDuration: Double
        var iso: Float
        var aperture: Float
    }

    var onResult: ((Result) -> Void)? {
        get { lock.withLock { storedOnResult } }
        set { lock.withLock { storedOnResult = newValue } }
    }

    private let minInterval: TimeInterval = 0.2
    private let gridSize = 8
    private let clipFraction = 0.10
    private let saturation: Float = 0.92
    private let noiseFloor: Float = 0.002
    private let outlierRatio: Float = 2.0

    private static let faceAreas: [CGRect] = [
        CGRect(x: 0.30, y: 0.78, width: 0.40, height: 0.14),
        CGRect(x: 0.12, y: 0.30, width: 0.24, height: 0.20),
        CGRect(x: 0.64, y: 0.30, width: 0.24, height: 0.20),
        CGRect(x: 0.42, y: 0.42, width: 0.16, height: 0.16),
        CGRect(x: 0.38, y: 0.08, width: 0.24, height: 0.12)
    ]

    private let queue = DispatchQueue(label: "lighting.face-lux", qos: .utility)
    private let request = VNDetectFaceRectanglesRequest()
    private let lock = NSLock()
    private var storedOnResult: ((Result) -> Void)?
    private var isBusy = false
    private var gate = RateGate()

    private static let linearTable: [Float] = (0..<256).map { value in
        let v = Float(value) / 255
        return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }

    func submit(buffer: CVPixelBuffer, time: Double, exposureDuration: Double, iso: Float, aperture: Float) {
        let accepted = lock.withLock { () -> Bool in
            guard !isBusy, gate.allow(now: time, interval: minInterval) else { return false }
            isBusy = true
            return true
        }
        guard accepted else { return }

        nonisolated(unsafe) let pixels = buffer
        queue.async { [self] in
            let (areaLuma, redness, faceHeight) = measure(pixels)
            let result = Result(areaLuma: areaLuma, redness: redness, faceHeight: faceHeight, exposureDuration: exposureDuration, iso: iso, aperture: aperture)
            let callback = lock.withLock { () -> ((Result) -> Void)? in
                isBusy = false
                return storedOnResult
            }
            callback?(result)
        }
    }

    private func measure(_ buffer: CVPixelBuffer) -> (areaLuma: [Float?], redness: Float?, faceHeight: Float?) {
        let none = [Float?](repeating: nil, count: Self.faceAreas.count)
        guard CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA else { return (none, nil, nil) }
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return (none, nil, nil) }
        let frame = Frame(bytes: base.assumingMemoryBound(to: UInt8.self),
                          stride: CVPixelBufferGetBytesPerRow(buffer),
                          width: CVPixelBufferGetWidth(buffer),
                          height: CVPixelBufferGetHeight(buffer))

        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .leftMirrored)
        guard (try? handler.perform([request])) != nil,
              let face = request.results?.max(by: { $0.boundingBox.height < $1.boundingBox.height })?.boundingBox else {
            let center = sample(frame, CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6))
            return (none, center.map { $0.red / max($0.green, 0.0001) }, nil)
        }

        let samples = Self.faceAreas.map { area in
            sample(frame, CGRect(x: face.minX + area.minX * face.width,
                                 y: face.minY + area.minY * face.height,
                                 width: area.width * face.width,
                                 height: area.height * face.height))
        }
        let luma = accept(samples.map { $0?.luma })
        let kept = zip(samples, luma).compactMap { $1 == nil ? nil : $0 }
        let pool = kept.isEmpty ? samples.compactMap { $0 } : kept
        let red = pool.reduce(0) { $0 + $1.red }
        let green = pool.reduce(0) { $0 + $1.green }
        return (luma, pool.isEmpty ? nil : red / max(green, 0.0001), Float(face.height))
    }

    private func accept(_ values: [Float?]) -> [Float?] {
        var result = values.map { value -> Float? in
            guard let value, value <= saturation, value >= noiseFloor else { return nil }
            return value
        }
        let valid = result.compactMap { $0 }.sorted()
        guard valid.count >= 3 else { return result }
        let median = valid[valid.count / 2]
        for i in result.indices {
            if let value = result[i], value > median * outlierRatio { result[i] = nil }
        }
        return result
    }

    private struct Frame {
        let bytes: UnsafePointer<UInt8>
        let stride: Int
        let width: Int
        let height: Int
    }

    private func sample(_ frame: Frame, _ rect: CGRect) -> (luma: Float, red: Float, green: Float)? {
        let rowStart = rect.minX * CGFloat(frame.height)
        let rowEnd = rect.maxX * CGFloat(frame.height)
        let columnStart = (1 - rect.maxY) * CGFloat(frame.width)
        let columnEnd = (1 - rect.minY) * CGFloat(frame.width)
        guard rowEnd > rowStart, columnEnd > columnStart else { return nil }

        var lumas: [Float] = []
        lumas.reserveCapacity(gridSize * gridSize)
        var redSum: Float = 0
        var greenSum: Float = 0
        for i in 0..<gridSize {
            let row = min(max(Int(rowStart + (CGFloat(i) + 0.5) / CGFloat(gridSize) * (rowEnd - rowStart)), 0), frame.height - 1)
            for j in 0..<gridSize {
                let column = min(max(Int(columnStart + (CGFloat(j) + 0.5) / CGFloat(gridSize) * (columnEnd - columnStart)), 0), frame.width - 1)
                let pixel = frame.bytes + row * frame.stride + column * 4
                let blue = Self.linearTable[Int(pixel[0])]
                let green = Self.linearTable[Int(pixel[1])]
                let red = Self.linearTable[Int(pixel[2])]
                lumas.append(0.2126 * red + 0.7152 * green + 0.0722 * blue)
                redSum += red
                greenSum += green
            }
        }
        lumas.sort()
        let kept = lumas.dropLast(Int(Double(lumas.count) * clipFraction))
        guard !kept.isEmpty else { return nil }
        return (kept[kept.startIndex + kept.count / 2], redSum, greenSum)
    }
}
