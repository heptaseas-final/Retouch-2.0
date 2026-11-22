import CoreGraphics
import Foundation

nonisolated struct FaceLayoutGate {
    private(set) var layout: FaceZoneLayout = .frontal
    private var pending: (layout: FaceZoneLayout, since: Date, seen: Date)?

    mutating func update(points: FacePoints, isFrozen: Bool, now: Date) -> FaceZoneLayout {
        guard !isFrozen, let offset = FaceZoneFrame(points: points)?.noseOffset else {
            pending = nil
            return layout
        }
        let wanted = wantedLayout(offset: offset)
        guard wanted != layout else {
            if let seen = pending?.seen, now.timeIntervalSince(seen) > FaceZoneConfig.turnGrace { pending = nil }
            return layout
        }
        if let current = pending, current.layout == wanted {
            pending = (wanted, current.since, now)
        } else {
            pending = (wanted, now, now)
        }
        if let since = pending?.since, now.timeIntervalSince(since) >= FaceZoneConfig.turnDwell {
            layout = wanted
            pending = nil
        }
        return layout
    }

    mutating func reset() {
        layout = .frontal
        pending = nil
    }

    private func wantedLayout(offset: CGFloat) -> FaceZoneLayout {
        let visibleSide: FaceSide = offset < 0 ? .right : .left
        switch layout {
        case .frontal:
            return abs(offset) >= FaceZoneConfig.turnEnter ? .turned(visibleSide: visibleSide) : .frontal
        case .turned(let current):
            if abs(offset) <= FaceZoneConfig.turnExit { return .frontal }
            return current == visibleSide ? layout : .turned(visibleSide: visibleSide)
        }
    }
}
