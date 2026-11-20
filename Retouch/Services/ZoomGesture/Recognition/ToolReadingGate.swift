import CoreGraphics
import Foundation

nonisolated struct ToolReadingGate {
    let points: FacePoints
    let tools: [TrackedTool]
    let detectedAt: Date
    let enterDistance: Double
    let maxIntentSpeed: CGFloat
    let locked: FaceZone?
    let support: Bool

    func read(now: Date) -> ToolZoneReading {
        guard !tools.isEmpty,
              now.timeIntervalSince(detectedAt) <= ToolDetectionTuning.maxResultAge else {
            return ToolZoneReading()
        }
        return ToolZoneRecognizer(points: points, tools: tools, enterDistance: enterDistance,
                                  maxIntentSpeed: maxIntentSpeed, locked: locked,
                                  support: support).read()
    }
}
