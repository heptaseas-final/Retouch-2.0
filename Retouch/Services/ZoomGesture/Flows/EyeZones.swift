import CoreGraphics

nonisolated enum EyeSide { case left, right }

nonisolated struct EyeZones {
    private let leftEye: CGPoint
    private let rightEye: CGPoint
    private let mid: CGPoint
    private let u: CGPoint
    private let v: CGPoint
    private let d: CGFloat
    private let lineT: CGFloat?

    var triggerScale: CGFloat = 1

    init?(points: FacePoints) {
        guard let l = points.leftEye, let r = points.rightEye, points.scale > 0 else { return nil }
        let len = hypot(r.x - l.x, r.y - l.y)
        guard len > 0 else { return nil }
        leftEye = l
        rightEye = r
        d = points.scale
        mid = CGPoint(x: (l.x + r.x) / 2, y: (l.y + r.y) / 2)
        u = CGPoint(x: (r.x - l.x) / len, y: (r.y - l.y) / len)
        v = CGPoint(x: -u.y, y: u.x)
        let m = mid, vv = v, scale = points.scale
        func along(_ p: CGPoint) -> CGFloat { ((p.x - m.x) * vv.x + (p.y - m.y) * vv.y) / scale }
        var line: CGFloat?
        if let top = points.lipsTop {
            line = along(top) + ZoomTuning.lipsLineOffset
        } else if let lips = points.lips {
            line = along(lips) * 0.5
        }
        if let lv = line, lv > 0 { lineT = lv } else { lineT = nil }
    }

    private var halfGap: CGFloat { ZoomTuning.zoneGap / 2 }

    func s(_ p: CGPoint) -> CGFloat { ((p.x - mid.x) * u.x + (p.y - mid.y) * u.y) / d }

    func t(_ p: CGPoint) -> CGFloat { ((p.x - mid.x) * v.x + (p.y - mid.y) * v.y) / d }

    func isLipsSide(_ p: CGPoint) -> Bool {
        guard let lt = lineT else { return false }
        return t(p) > lt + halfGap
    }

    func isLipsHoldSide(_ p: CGPoint) -> Bool {
        guard let lt = lineT else { return false }
        return t(p) >= lt
    }

    func isAboveLips(_ p: CGPoint, hold: Bool = false) -> Bool {
        guard let lt = lineT else { return true }
        return hold ? t(p) < lt : t(p) < lt - halfGap
    }

    func ownsSide(_ side: EyeSide, _ p: CGPoint, hold: Bool) -> Bool {
        let edge = hold ? 0 : halfGap
        let x = s(p)
        return side == .left ? x < -edge : x >= edge
    }

    private func eye(_ side: EyeSide) -> CGPoint { side == .left ? leftEye : rightEye }

    private func shapeRadii(a: CGFloat, b: CGFloat, side: EyeSide) -> (x: CGFloat, y: CGFloat) {
        let outward = side == .left ? -a : a
        let x = ZoomTuning.eyeTriggerRadiusX * (outward > 0 ? ZoomTuning.eyeShapeOuter : ZoomTuning.eyeShapeInner)
        let y = ZoomTuning.eyeTriggerRadiusY * (b > 0 ? ZoomTuning.eyeShapeDown : ZoomTuning.eyeShapeUp)
        return (x, y)
    }

    func triggerEye(at p: CGPoint, owner: CGPoint? = nil) -> EyeSide? {
        guard isAboveLips(owner ?? p) else { return nil }
        if ownsSide(.left, p, hold: false), triggerValue(p, to: .left) <= 1 { return .left }
        if ownsSide(.right, p, hold: false), triggerValue(p, to: .right) <= 1 { return .right }
        return nil
    }

    func holds(_ side: EyeSide, at p: CGPoint, grip: Bool = false) -> Bool {
        guard isAboveLips(p, hold: true), ownsSide(side, p, hold: true) else { return false }
        let value = grip ? gripValue(p, to: side) : triggerValue(p, to: side)
        return value <= ZoomTuning.eyeHoldScale
    }

    func inEyeTerritory(_ p: CGPoint, margin: CGFloat = 0) -> Bool {
        guard isAboveLips(p, hold: true) else { return false }
        var widest = self
        widest.triggerScale = ZoomTuning.maxTriggerScale * ZoomTuning.eyeHoldScale + margin
        return widest.gripValue(p, to: .left) <= 1 || widest.gripValue(p, to: .right) <= 1
    }

    func gripValue(_ p: CGPoint, to side: EyeSide) -> CGFloat {
        let e = eye(side)
        let dx = p.x - e.x, dy = p.y - e.y
        let a = (dx * u.x + dy * u.y) / d
        let b = (dx * v.x + dy * v.y) / d
        let outward = side == .left ? -a : a
        let sx = outward > 0 ? ZoomTuning.eyeGripScaleOuter : ZoomTuning.eyeGripScaleInner
        let radii = shapeRadii(a: a, b: b, side: side)
        let rx = radii.x * triggerScale * sx
        let ry = radii.y * triggerScale * ZoomTuning.eyeGripScaleY
        return hypot(a / rx, b / ry)
    }

    func gripTriggerEye(at p: CGPoint, owner: CGPoint? = nil) -> EyeSide? {
        guard isAboveLips(owner ?? p) else { return nil }
        if ownsSide(.left, p, hold: false), gripValue(p, to: .left) <= 1 { return .left }
        if ownsSide(.right, p, hold: false), gripValue(p, to: .right) <= 1 { return .right }
        return nil
    }

    var axisU: CGPoint { u }
    var axisV: CGPoint { v }

    func triggerValue(_ p: CGPoint, to side: EyeSide) -> CGFloat {
        let e = eye(side)
        let dx = p.x - e.x, dy = p.y - e.y
        let a = (dx * u.x + dy * u.y) / d
        let b = (dx * v.x + dy * v.y) / d
        let radii = shapeRadii(a: a, b: b, side: side)
        let rx = radii.x * triggerScale
        let ry = radii.y * triggerScale
        return hypot(a / rx, b / ry)
    }
}
