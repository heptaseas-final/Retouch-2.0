//
//  ToolTipLocator.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 19/11/26.
//
import CoreGraphics

nonisolated enum ToolTipLocator {
    static func tip(of rect: CGRect, face: FacePoints) -> CGPoint {
        guard let anchor = anchor(of: face) else { return CGPoint(x: rect.midX, y: rect.midY) }
        return tip(of: rect, toward: anchor)
    }

    static func tip(of rect: CGRect, toward anchor: CGPoint) -> CGPoint {
        let short = min(rect.width, rect.height)
        let long = max(rect.width, rect.height)
        guard short > 0 else { return CGPoint(x: rect.midX, y: rect.midY) }
        let stretch = (long / short - 1) / (ToolDetectionTuning.tipElongated - 1)
        let pull = short / 2 * min(max(stretch, ToolDetectionTuning.tipMinPull), 1)
        let corners = [
            CGPoint(x: rect.minX + pull, y: rect.minY + pull),
            CGPoint(x: rect.maxX - pull, y: rect.minY + pull),
            CGPoint(x: rect.minX + pull, y: rect.maxY - pull),
            CGPoint(x: rect.maxX - pull, y: rect.maxY - pull)
        ]
        func distance(_ p: CGPoint) -> CGFloat { hypot(p.x - anchor.x, p.y - anchor.y) }
        return corners.min { distance($0) < distance($1) } ?? CGPoint(x: rect.midX, y: rect.midY)
    }

    private static func anchor(of face: FacePoints) -> CGPoint? {
        if let center = face.center { return center }
        if let nose = face.nose { return nose }
        guard let l = face.leftEye, let r = face.rightEye else { return nil }
        return CGPoint(x: (l.x + r.x) / 2, y: (l.y + r.y) / 2)
    }
}
