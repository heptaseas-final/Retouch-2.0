//
//  ToolTipLocator.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 19/11/26.
//
import CoreGraphics

nonisolated enum ToolTipLocator {
    static func tip(of tool: TrackedTool, face: FacePoints) -> CGPoint {
        let rect = tool.rect
        let targets = face.handTargets.map(\.1)
        let candidates = ends(of: rect)
        guard !targets.isEmpty, let bestScore = candidates.map({ score($0, targets) }).min() else {
            return tip(of: rect, face: face)
        }
        let tolerance = ToolDetectionTuning.tipAmbiguity * face.width
        let close = candidates.filter { score($0, targets) - bestScore <= tolerance }
        guard let grip = tool.grip, close.count > 1 else {
            return candidates.min { score($0, targets) < score($1, targets) } ?? CGPoint(x: rect.midX, y: rect.midY)
        }
        return close.max { distance($0, grip) < distance($1, grip) } ?? CGPoint(x: rect.midX, y: rect.midY)
    }

    static func tip(of rect: CGRect, face: FacePoints) -> CGPoint {
        guard let anchor = anchor(of: face) else { return CGPoint(x: rect.midX, y: rect.midY) }
        return tip(of: rect, toward: anchor)
    }

    static func tip(of rect: CGRect, toward anchor: CGPoint) -> CGPoint {
        ends(of: rect).min { distance($0, anchor) < distance($1, anchor) } ?? CGPoint(x: rect.midX, y: rect.midY)
    }

    private static func ends(of rect: CGRect) -> [CGPoint] {
        let short = min(rect.width, rect.height)
        let long = max(rect.width, rect.height)
        guard short > 0 else { return [CGPoint(x: rect.midX, y: rect.midY)] }
        let stretch = min(max((long / short - 1) / (ToolDetectionTuning.tipElongated - 1), 0), 1)
        let across = short / 2 * max(stretch, ToolDetectionTuning.tipMinPull)
        let along = short / 2 * ToolDetectionTuning.tipMinPull * (1 - stretch)
        let isWide = rect.width >= rect.height
        let dx = isWide ? along : across
        let dy = isWide ? across : along
        return [
            CGPoint(x: rect.minX + dx, y: rect.minY + dy),
            CGPoint(x: rect.maxX - dx, y: rect.minY + dy),
            CGPoint(x: rect.minX + dx, y: rect.maxY - dy),
            CGPoint(x: rect.maxX - dx, y: rect.maxY - dy)
        ]
    }

    private static func score(_ end: CGPoint, _ targets: [CGPoint]) -> CGFloat {
        targets.map { distance(end, $0) }.min() ?? 0
    }

    private static func distance(_ p: CGPoint, _ q: CGPoint) -> CGFloat { hypot(p.x - q.x, p.y - q.y) }

    private static func anchor(of face: FacePoints) -> CGPoint? {
        if let center = face.center { return center }
        if let nose = face.nose { return nose }
        guard let l = face.leftEye, let r = face.rightEye else { return nil }
        return CGPoint(x: (l.x + r.x) / 2, y: (l.y + r.y) / 2)
    }
}
