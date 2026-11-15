import CoreGraphics
import Foundation
import Testing
@testable import Retouch

struct ToolReadingGateTests {
    private let detectedAt = Date(timeIntervalSinceReferenceDate: 1000)
    private let atLeftEye = CGRect(x: 85, y: 85, width: 30, height: 30)

    private func makePoints() -> FacePoints {
        var points = FacePoints()
        points.leftEye = CGPoint(x: 100, y: 100)
        points.rightEye = CGPoint(x: 200, y: 100)
        points.lips = CGPoint(x: 150, y: 220)
        points.center = CGPoint(x: 150, y: 150)
        points.width = 260
        points.scale = 100
        return points
    }

    private func gate(confidence: Float = 0.8, tools: [TrackedTool]? = nil) -> ToolReadingGate {
        let list = tools ?? [TrackedTool(label: .brush, confidence: confidence, rect: atLeftEye, speed: 0)]
        return ToolReadingGate(points: makePoints(), tools: list, detectedAt: detectedAt,
                               enterDistance: 0.38, maxIntentSpeed: 1.2, noseActive: false, support: false)
    }

    @Test func freshResultTriggers() {
        let reading = gate().read(now: detectedAt.addingTimeInterval(0.3))
        #expect(reading.eyeTriggerLeft)
        #expect(reading.isInZone)
    }

    @Test func resultAtMaxAgeStillCounts() {
        let reading = gate().read(now: detectedAt.addingTimeInterval(ToolDetectionTuning.maxResultAge))
        #expect(reading.eyeTriggerLeft)
    }

    @Test func resultOlderThanMaxAgeIsTreatedAsMissing() {
        let reading = gate().read(now: detectedAt.addingTimeInterval(ToolDetectionTuning.maxResultAge + 0.01))
        #expect(reading == ToolZoneReading())
    }

    @Test func noToolsMeansEmptyReading() {
        #expect(gate(tools: []).read(now: detectedAt) == ToolZoneReading())
    }

    @Test func confidenceBelowTriggerOnlyHolds() {
        let reading = gate(confidence: 0.45).read(now: detectedAt)
        #expect(!reading.eyeTriggerLeft)
        #expect(reading.eyeHoldLeft)
    }

    @Test func confidenceBelowHoldFloorIsDropped() {
        #expect(gate(confidence: 0.34).read(now: detectedAt) == ToolZoneReading())
    }
}
