import CoreGraphics
import Foundation
import Testing
@testable import Retouch

struct ToolBoxTrackerTests {
    private let converter = CoordinateConverter(imageSize: CGSize(width: 720, height: 1280),
                                                viewSize: CGSize(width: 720, height: 1280))
    private let start = Date(timeIntervalSinceReferenceDate: 1000)
    private let maxSpeed: CGFloat = 1.2
    private let faceWidth: CGFloat = 300

    private func detection(x: CGFloat = 0.4, label: ToolDetection.Label = .brush) -> ToolDetection {
        ToolDetection(label: label, confidence: 0.8, box: CGRect(x: x, y: 0.5, width: 0.1, height: 0.05))
    }

    private func step(_ tracker: inout ToolBoxTracker, _ detections: [ToolDetection], at seconds: Double) -> [TrackedTool] {
        tracker.update(detections, converter: converter, faceWidth: faceWidth, maxIntentSpeed: maxSpeed,
                       now: start.addingTimeInterval(seconds))
    }

    @Test func convertsBoxToViewRect() throws {
        var tracker = ToolBoxTracker()
        let tools = step(&tracker, [detection()], at: 0)
        let tool = try #require(tools.first)
        #expect(abs(tool.rect.minX - 288) < 0.001)
        #expect(abs(tool.rect.minY - 576) < 0.001)
        #expect(abs(tool.rect.width - 72) < 0.001)
        #expect(abs(tool.rect.height - 64) < 0.001)
    }

    @Test func newToolCountsAsFast() throws {
        var tracker = ToolBoxTracker()
        let tools = step(&tracker, [detection()], at: 0)
        let tool = try #require(tools.first)
        #expect(tool.speed >= maxSpeed)
    }

    @Test func stationaryToolBecomesSlow() throws {
        var tracker = ToolBoxTracker()
        _ = step(&tracker, [detection()], at: 0)
        _ = step(&tracker, [detection()], at: 0.1)
        let tools = step(&tracker, [detection()], at: 0.2)
        let tool = try #require(tools.first)
        #expect(tool.speed < maxSpeed)
    }

    @Test func movingToolStaysFast() throws {
        var tracker = ToolBoxTracker()
        _ = step(&tracker, [detection(x: 0.1)], at: 0)
        _ = step(&tracker, [detection(x: 0.2)], at: 0.1)
        let tools = step(&tracker, [detection(x: 0.3)], at: 0.2)
        let tool = try #require(tools.first)
        #expect(tool.speed >= maxSpeed)
    }

    @Test func missedFrameKeepsTrack() throws {
        var tracker = ToolBoxTracker()
        _ = step(&tracker, [detection()], at: 0)
        _ = step(&tracker, [detection()], at: 0.1)
        _ = step(&tracker, [], at: 0.2)
        _ = step(&tracker, [detection()], at: 0.3)
        let tools = step(&tracker, [detection()], at: 0.4)
        let tool = try #require(tools.first)
        #expect(tool.speed < maxSpeed)
    }

    @Test func returnsNothingWithoutFaceWidth() {
        var tracker = ToolBoxTracker()
        let tools = tracker.update([detection()], converter: converter, faceWidth: 0,
                                   maxIntentSpeed: maxSpeed, now: start)
        #expect(tools.isEmpty)
    }
}
