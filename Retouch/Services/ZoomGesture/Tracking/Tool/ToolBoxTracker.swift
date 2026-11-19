import CoreGraphics
import Foundation

nonisolated struct TrackedTool: Equatable {
    let label: ToolDetection.Label
    let confidence: Float
    let rect: CGRect
    let speed: CGFloat

    var center: CGPoint { CGPoint(x: rect.midX, y: rect.midY) }
}

nonisolated struct ToolBoxTracker {
    private struct Track {
        var label: ToolDetection.Label
        var center: CGPoint
        var time: TimeInterval
        var speed: CGFloat
    }

    private var tracks: [Track] = []

    mutating func update(_ detections: [ToolDetection], converter: CoordinateConverter,
                         faceWidth: CGFloat, maxIntentSpeed: CGFloat, now: Date) -> [TrackedTool] {
        guard faceWidth > 0 else {
            tracks = []
            return []
        }
        let t = now.timeIntervalSinceReferenceDate
        tracks.removeAll { t - $0.time > ToolDetectionTuning.trackMaxGap }

        let rects = detections.map { Self.viewRect($0.box, converter: converter) }

        var pairs: [(detection: Int, track: Int, distance: CGFloat)] = []
        for (di, detection) in detections.enumerated() {
            let c = CGPoint(x: rects[di].midX, y: rects[di].midY)
            for (ti, track) in tracks.enumerated() where track.label == detection.label {
                let d = hypot(c.x - track.center.x, c.y - track.center.y) / faceWidth
                if d <= ToolDetectionTuning.trackJumpDistance { pairs.append((di, ti, d)) }
            }
        }
        pairs.sort { $0.distance < $1.distance }
        var trackOfDetection: [Int: Int] = [:]
        var usedTracks = Set<Int>()
        for pair in pairs where trackOfDetection[pair.detection] == nil && !usedTracks.contains(pair.track) {
            trackOfDetection[pair.detection] = pair.track
            usedTracks.insert(pair.track)
        }

        var result: [TrackedTool] = []
        var next: [Track] = []
        for (di, detection) in detections.enumerated() {
            let rect = rects[di]
            let center = CGPoint(x: rect.midX, y: rect.midY)
            var speed = maxIntentSpeed * 2
            if let ti = trackOfDetection[di] {
                let previous = tracks[ti]
                let dt = max(t - previous.time, 0.001)
                let instant = hypot(center.x - previous.center.x, center.y - previous.center.y)
                    / faceWidth / CGFloat(dt)
                let alpha = CGFloat(1 - exp(-min(dt, ZoomTuning.maxStep) / Double(ZoomTuning.handSpeedTau)))
                speed = previous.speed + alpha * (instant - previous.speed)
            }
            next.append(Track(label: detection.label, center: center, time: t, speed: speed))
            result.append(TrackedTool(label: detection.label, confidence: detection.confidence,
                                      rect: rect, speed: speed))
        }
        for (ti, track) in tracks.enumerated() where !usedTracks.contains(ti) {
            next.append(track)
        }
        tracks = next
        return result
    }

    mutating func reset() { tracks = [] }

    private static func viewRect(_ box: CGRect, converter: CoordinateConverter) -> CGRect {
        let a = converter.toView(CGPoint(x: box.minX, y: box.minY))
        let b = converter.toView(CGPoint(x: box.maxX, y: box.maxY))
        return CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
    }
}
