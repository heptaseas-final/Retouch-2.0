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
        let inset = min(rect.width, rect.height) / 2 * ToolDetectionTuning.tipInset
        let minX = min(rect.minX + inset, rect.midX)
        let maxX = max(rect.maxX - inset, rect.midX)
        let minY = min(rect.minY + inset, rect.midY)
        let maxY = max(rect.maxY - inset, rect.midY)
        return CGPoint(x: min(max(anchor.x, minX), maxX), y: min(max(anchor.y, minY), maxY))
    }

    private static func anchor(of face: FacePoints) -> CGPoint? {
        if let center = face.center { return center }
        if let nose = face.nose { return nose }
        guard let l = face.leftEye, let r = face.rightEye else { return nil }
        return CGPoint(x: (l.x + r.x) / 2, y: (l.y + r.y) / 2)
    }
}