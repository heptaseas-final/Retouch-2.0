//
//  FaceZoneMap.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 19/11/26.
//


import CoreGraphics

nonisolated struct FaceZoneMap {
    private let eyes: EyeZones
    private let noseS: CGFloat?
    private let line: CGFloat?
    private let lips: CGPoint?
    private let faceWidth: CGFloat
    private let lipsRadiusX: CGFloat
    private let lipsRadiusY: CGFloat
    private let noseHalfWidth: CGFloat

    init?(points: FacePoints, reach: CGFloat = 1,
          lipsReach: CGFloat = CGFloat(ZoomTuning.handEnterDistance)) {
        guard var eyes = EyeZones(points: points) else { return nil }
        eyes.triggerScale = reach
        self.eyes = eyes
        noseS = points.nose.map { eyes.s($0) }
        line = Self.lipsLine(points, eyes)
        lips = points.lips
        faceWidth = points.width
        lipsRadiusX = lipsReach * ZoomTuning.lipsTriggerStretchX
        lipsRadiusY = lipsReach * ZoomTuning.lipsTriggerStretchY
        noseHalfWidth = ZoomTuning.noseColumnHalfWidth * reach
    }

    func zone(of p: CGPoint, locked: FaceZone? = nil) -> FaceZone? {
        if let locked, contains(locked, p, grown: true) { return locked }
        if contains(.lips, p, grown: false) { return .lips }
        let left = contains(.leftEye, p, grown: false)
        let right = contains(.rightEye, p, grown: false)
        if left, right {
            return eyes.triggerValue(p, to: .left) <= eyes.triggerValue(p, to: .right) ? .leftEye : .rightEye
        }
        if left { return .leftEye }
        if right { return .rightEye }
        if contains(.nose, p, grown: false) { return .nose }
        return nil
    }

    func holds(_ zone: FaceZone, at p: CGPoint) -> Bool {
        self.zone(of: p, locked: zone) == zone
    }

    private func contains(_ zone: FaceZone, _ p: CGPoint, grown: Bool) -> Bool {
        let scale = grown ? ZoomTuning.zoneLockScale : 1
        let margin = grown ? ZoomTuning.zoneLockMargin : 0
        let t = eyes.t(p)
        switch zone {
        case .leftEye, .rightEye:
            if let line, t >= line + margin { return false }
            return eyes.triggerValue(p, to: zone == .leftEye ? .left : .right) <= scale
        case .nose:
            guard let noseS, let line else { return false }
            return abs(eyes.s(p) - noseS) <= noseHalfWidth * scale
                && t >= ZoomTuning.noseColumnTop - margin
                && t < line + margin
        case .lips:
            guard let line, let lips, faceWidth > 0, t >= line - margin else { return false }
            let dx = p.x - lips.x, dy = p.y - lips.y
            let a = (dx * eyes.axisU.x + dy * eyes.axisU.y) / faceWidth
            let b = (dx * eyes.axisV.x + dy * eyes.axisV.y) / faceWidth
            return hypot(a / (lipsRadiusX * scale), b / (lipsRadiusY * scale)) < 1
        }
    }

    private static func lipsLine(_ points: FacePoints, _ eyes: EyeZones) -> CGFloat? {
        let top = points.lipsTop.map { eyes.t($0) }
            ?? points.lips.map { eyes.t($0) * ZoomTuning.lipsLineFallback }
        guard var line = top else { return nil }
        if let nose = points.nose, let top {
            let noseT = eyes.t(nose)
            if top > noseT { line = (noseT + top) / 2 }
        }
        line += ZoomTuning.lipsLineOffset
        return line > 0 ? line : nil
    }
}