//
//  FrameMotionTracker.swift
//  Retouch
//
//  Created by Davin P on 09/11/26.
//

import CoreVideo
import Foundation

nonisolated final class FrameMotionTracker {
    private struct Level {
        var width: Int
        var height: Int
        var pixels: [Float]
    }

    private let baseWidth = 160
    private let grid = 3
    private let levelCount = 2
    private let iterations = 3
    private let maxCellShift: Float = 8
    private let minCells = 3
    private let maxSpread: Float = 1.0
    private let minTexture: Float = 0.5

    private var previous: [Level] = []

    func frameShift(_ buffer: CVPixelBuffer, active: Bool) -> SIMD2<Double>? {
        guard active, let current = pyramid(of: buffer) else {
            reset()
            return nil
        }
        defer { previous = current }
        guard let first = previous.first,
              first.width == current[0].width, first.height == current[0].height,
              let shift = measure(from: previous, to: current) else { return nil }
        return SIMD2(Double(shift.x) / Double(current[0].width),
                     Double(shift.y) / Double(current[0].height))
    }

    func reset() { previous = [] }

    private func pyramid(of buffer: CVPixelBuffer) -> [Level]? {
        guard CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA else { return nil }
        let sourceWidth = CVPixelBufferGetWidth(buffer)
        let sourceHeight = CVPixelBufferGetHeight(buffer)
        guard sourceWidth >= baseWidth * 2 else { return nil }
        let height = baseWidth * sourceHeight / sourceWidth
        let stepX = sourceWidth / baseWidth
        let stepY = sourceHeight / height
        guard height >= 16, stepY >= 2 else { return nil }

        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let address = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let bytes = address.assumingMemoryBound(to: UInt8.self)
        let stride = CVPixelBufferGetBytesPerRow(buffer)

        var pixels = [Float](repeating: 0, count: baseWidth * height)
        for y in 0..<height {
            let sourceY = y * stepY + stepY / 2 - 1
            for x in 0..<baseWidth {
                let sourceX = x * stepX + stepX / 2 - 1
                var sum: Float = 0
                for offsetY in 0..<2 {
                    let row = bytes + (sourceY + offsetY) * stride + sourceX * 4
                    for offsetX in 0..<2 {
                        let p = row + offsetX * 4
                        sum += 0.114 * Float(p[0]) + 0.587 * Float(p[1]) + 0.299 * Float(p[2])
                    }
                }
                pixels[y * baseWidth + x] = sum * 0.25
            }
        }
        let fine = Level(width: baseWidth, height: height, pixels: pixels)
        return [fine, Self.halved(fine)]
    }

    private static func halved(_ level: Level) -> Level {
        let width = level.width / 2
        let height = level.height / 2
        var pixels = [Float](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let i = (2 * y) * level.width + 2 * x
                pixels[y * width + x] = (level.pixels[i] + level.pixels[i + 1]
                    + level.pixels[i + level.width] + level.pixels[i + level.width + 1]) * 0.25
            }
        }
        return Level(width: width, height: height, pixels: pixels)
    }

    private func measure(from old: [Level], to new: [Level]) -> SIMD2<Float>? {
        let width = old[0].width
        let height = old[0].height
        var xs: [Float] = []
        var ys: [Float] = []
        for row in 0..<grid {
            for column in 0..<grid {
                let rect = (x0: column * width / grid, y0: row * height / grid,
                            x1: (column + 1) * width / grid, y1: (row + 1) * height / grid)
                guard let d = translation(old, new, rect),
                      abs(d.x) <= maxCellShift, abs(d.y) <= maxCellShift else { continue }
                xs.append(d.x)
                ys.append(d.y)
            }
        }
        guard xs.count >= minCells else { return nil }
        let medianX = Self.median(xs)
        let medianY = Self.median(ys)
        let spread = max(Self.median(xs.map { abs($0 - medianX) }), Self.median(ys.map { abs($0 - medianY) }))
        return spread <= maxSpread ? SIMD2<Float>(medianX, medianY) : nil
    }

    private func translation(_ old: [Level], _ new: [Level],
                             _ rect: (x0: Int, y0: Int, x1: Int, y1: Int)) -> SIMD2<Float>? {
        var d = SIMD2<Float>(0, 0)
        for index in stride(from: levelCount - 1, through: 0, by: -1) {
            let reference = old[index]
            let target = new[index]
            let scale = 1 << index
            if index < levelCount - 1 { d *= 2 }

            let x0 = max(rect.x0 / scale, 2), x1 = min(rect.x1 / scale, reference.width - 2)
            let y0 = max(rect.y0 / scale, 2), y1 = min(rect.y1 / scale, reference.height - 2)
            guard x1 - x0 > 4, y1 - y0 > 4 else { return nil }
            let count = Float((x1 - x0) * (y1 - y0))

            for _ in 0..<iterations {
                var sxx: Float = 0, sxy: Float = 0, syy: Float = 0
                var bx: Float = 0, by: Float = 0
                for y in y0..<y1 {
                    for x in x0..<x1 {
                        let i = y * reference.width + x
                        let gx = (reference.pixels[i + 1] - reference.pixels[i - 1]) * 0.5
                        let gy = (reference.pixels[i + reference.width] - reference.pixels[i - reference.width]) * 0.5
                        let diff = Self.sample(target, Float(x) + d.x, Float(y) + d.y) - reference.pixels[i]
                        sxx += gx * gx
                        sxy += gx * gy
                        syy += gy * gy
                        bx += gx * diff
                        by += gy * diff
                    }
                }
                let det = sxx * syy - sxy * sxy
                guard det / (count * count) > minTexture else { return nil }
                d.x -= (syy * bx - sxy * by) / det
                d.y -= (sxx * by - sxy * bx) / det
            }
        }
        return d
    }

    private static func sample(_ level: Level, _ x: Float, _ y: Float) -> Float {
        let fx = min(max(x, 0), Float(level.width - 1) - 0.001)
        let fy = min(max(y, 0), Float(level.height - 1) - 0.001)
        let ix = Int(fx), iy = Int(fy)
        let tx = fx - Float(ix), ty = fy - Float(iy)
        let i = iy * level.width + ix
        let top = level.pixels[i] + (level.pixels[i + 1] - level.pixels[i]) * tx
        let bottom = level.pixels[i + level.width]
            + (level.pixels[i + level.width + 1] - level.pixels[i + level.width]) * tx
        return top + (bottom - top) * ty
    }

    private static func median(_ values: [Float]) -> Float {
        values.sorted()[values.count / 2]
    }
}
