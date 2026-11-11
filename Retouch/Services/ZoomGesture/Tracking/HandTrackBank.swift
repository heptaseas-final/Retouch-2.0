import CoreGraphics
import Foundation

nonisolated struct TrackedHand {
    let id: Int
    var point: CGPoint
    var speed: CGFloat
    var pose2: Bool
    var pose3: Bool
    var finger: CGPoint? = nil
    var holding = false
    var mode = ""
    var base: CGPoint? = nil
    var kept = false
    var isPoint = false
    var hasPose: Bool { pose2 || pose3 }
    var checkPoints: [CGPoint] {
        guard let f = finger else { return [point] }
        let mid = CGPoint(x: (point.x + f.x) / 2, y: (point.y + f.y) / 2)
        return [point, mid, f]
    }
}

nonisolated struct HandTrackBank {
    struct Candidate {
        var tip: CGPoint
        var pose2: Bool
        var pose3: Bool
        var finger: CGPoint? = nil
        var holding = false
        var mode = ""
        var base: CGPoint? = nil
        var kept = false
        var isPoint = false
    }

    var jumpDistance: CGFloat = 0.9
    var speedTau = ZoomTuning.handSpeedTau
    var maxHandGap = ZoomTuning.handMaxGap
    var maxIntentSpeed = CGFloat(ZoomTuning.handMaxSpeed)

    private struct Track {
        let id: Int
        var fx = OneEuroFilter()
        var fy = OneEuroFilter()
        var time: TimeInterval
        var point: CGPoint
        var speed: CGFloat
    }
    private var tracks: [Track] = []
    private var nextID = 1

    mutating func apply(_ profile: HandProfile) {
        maxIntentSpeed = CGFloat(profile.maxIntentSpeed)
    }

    mutating func reset() { tracks = [] }

    mutating func update(_ candidates: [Candidate], faceWidth W: CGFloat, viewHeight H: CGFloat,
                         now: Date) -> [TrackedHand] {
        guard W > 0 else {
            tracks = []
            return []
        }
        let t = now.timeIntervalSinceReferenceDate
        tracks.removeAll { t - $0.time > maxHandGap }

        var pairs: [(c: Int, k: Int, d: CGFloat)] = []
        for (ci, c) in candidates.enumerated() {
            for (ki, k) in tracks.enumerated() {
                let d = hypot(c.tip.x - k.point.x, c.tip.y - k.point.y) / W
                if d <= jumpDistance { pairs.append((ci, ki, d)) }
            }
        }
        pairs.sort { $0.d < $1.d }
        var matchOfCandidate: [Int: Int] = [:]
        var usedTracks = Set<Int>()
        for p in pairs where matchOfCandidate[p.c] == nil && !usedTracks.contains(p.k) {
            matchOfCandidate[p.c] = p.k
            usedTracks.insert(p.k)
        }

        var out: [TrackedHand] = []
        for (ci, c) in candidates.enumerated() {
            var track: Track
            let isNew: Bool
            if let ki = matchOfCandidate[ci] {
                track = tracks[ki]
                isNew = false
            } else {
                track = Track(id: nextID, time: t, point: c.tip, speed: maxIntentSpeed * 2)
                nextID += 1
                isNew = true
            }
            let dt = max(t - track.time, 0.001)
            let nx = track.fx.filter(Double(c.tip.x / H), t: t)
            let ny = track.fy.filter(Double(c.tip.y / H), t: t)
            let p = CGPoint(x: CGFloat(nx) * H, y: CGFloat(ny) * H)

            if !isNew {
                let instant = hypot(p.x - track.point.x, p.y - track.point.y) / W / CGFloat(dt)
                let alpha = CGFloat(1 - exp(-min(dt, ZoomTuning.maxStep) / Double(speedTau)))
                track.speed += alpha * (instant - track.speed)
            }
            track.point = p
            track.time = t

            if let ki = matchOfCandidate[ci] { tracks[ki] = track } else { tracks.append(track) }
            let finger = c.finger.map { CGPoint(x: p.x + ($0.x - c.tip.x), y: p.y + ($0.y - c.tip.y)) }
            let base = c.base.map { CGPoint(x: p.x + ($0.x - c.tip.x), y: p.y + ($0.y - c.tip.y)) }
            out.append(TrackedHand(id: track.id, point: p, speed: track.speed,
                                   pose2: c.pose2, pose3: c.pose3, finger: finger, holding: c.holding,
                                   mode: c.mode, base: base, kept: c.kept, isPoint: c.isPoint))
        }
        return out
    }
}
