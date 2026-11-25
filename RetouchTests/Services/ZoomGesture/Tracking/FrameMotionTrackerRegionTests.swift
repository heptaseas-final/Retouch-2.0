//
//  FrameMotionTrackerRegionTests.swift
//  Retouch
//
//  Created by Retouch Team on 23/11/26.
//

import CoreGraphics
import CoreVideo
import Foundation
import Testing
@testable import Retouch

struct FrameMotionTrackerRegionTests {
    private let width = 640
    private let height = 480
    private let face = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)
    private let tolerance = 0.1

    @Test func faceRegionMovementIsMeasured() throws {
        let result = try #require(try measured(moving: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6),
                                               by: SIMD2(2, 1)))
        #expect(abs(result.x * 160 - 2) < tolerance)
        #expect(abs(result.y * 120 - 1) < tolerance)
    }

    @Test func movementOutsideTheFaceIsIgnored() throws {
        let result = try #require(try measured(moving: CGRect(x: 0, y: 0, width: 1, height: 0.15),
                                               by: SIMD2(3, 0)))
        #expect(abs(result.x * 160) < tolerance)
        #expect(abs(result.y * 120) < tolerance)
    }

    @Test func tinyRegionGivesNothing() throws {
        let tracker = FrameMotionTracker()
        let still = try frame(moving: .zero, by: SIMD2(0, 0))
        let tiny = CGRect(x: 0.5, y: 0.5, width: 0.05, height: 0.05)
        _ = tracker.regionShift(still, region: tiny)
        #expect(tracker.regionShift(still, region: tiny) == nil)
    }

    private func measured(moving area: CGRect, by shift: SIMD2<Double>) throws -> SIMD2<Double>? {
        let tracker = FrameMotionTracker()
        _ = tracker.regionShift(try frame(moving: .zero, by: SIMD2(0, 0)), region: face)
        return tracker.regionShift(try frame(moving: area, by: shift), region: face)
    }

    private func frame(moving area: CGRect, by shift: SIMD2<Double>) throws -> CVPixelBuffer {
        var output: CVPixelBuffer?
        CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, nil, &output)
        let buffer = try #require(output)
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        let base = try #require(CVPixelBufferGetBaseAddress(buffer)).assumingMemoryBound(to: UInt8.self)
        let stride = CVPixelBufferGetBytesPerRow(buffer)
        let x0 = Int(area.minX * CGFloat(width)), x1 = Int(area.maxX * CGFloat(width))
        let y0 = Int(area.minY * CGFloat(height)), y1 = Int(area.maxY * CGFloat(height))
        for y in 0..<height {
            for x in 0..<width {
                let inside = x >= x0 && x < x1 && y >= y0 && y < y1
                let dx = inside ? shift.x * 4 : 0
                let dy = inside ? shift.y * 4 : 0
                let value = UInt8(min(max(texture(Double(x) - dx, Double(y) - dy).rounded(), 0), 255))
                let pixel = base + y * stride + x * 4
                pixel[0] = value
                pixel[1] = value
                pixel[2] = value
                pixel[3] = 255
            }
        }
        return buffer
    }

    private func texture(_ x: Double, _ y: Double) -> Double {
        128 + 40 * sin(x / 9) + 40 * sin(y / 11) + 30 * sin((x + y) / 7) + 20 * cos((x - 2 * y) / 13)
    }
}
