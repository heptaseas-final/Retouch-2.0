import CoreGraphics

nonisolated enum EyeSide { case left, right }

nonisolated struct EyeZones {
    private let leftEye: CGPoint
    private let rightEye: CGPoint
    private let mid: CGPoint
    private let u: CGPoint
    private let v: CGPoint
    private let d: CGFloat

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
    }

    var axisU: CGPoint { u }
    var axisV: CGPoint { v }

    func s(_ p: CGPoint) -> CGFloat { ((p.x - mid.x) * u.x + (p.y - mid.y) * u.y) / d }

    func t(_ p: CGPoint) -> CGFloat { ((p.x - mid.x) * v.x + (p.y - mid.y) * v.y) / d }

    func triggerValue(_ p: CGPoint, to side: EyeSide) -> CGFloat {
        let e = side == .left ? leftEye : rightEye
        let dx = p.x - e.x, dy = p.y - e.y
        let a = (dx * u.x + dy * u.y) / d
        let b = (dx * v.x + dy * v.y) / d
        let outward = side == .left ? -a : a
        let rx = ZoomTuning.eyeTriggerRadiusX
            * (outward > 0 ? ZoomTuning.eyeShapeOuter : ZoomTuning.eyeShapeInner) * triggerScale
        let ry = ZoomTuning.eyeTriggerRadiusY
            * (b > 0 ? ZoomTuning.eyeShapeDown : ZoomTuning.eyeShapeUp) * triggerScale
        return hypot(a / rx, b / ry)
    }
}
