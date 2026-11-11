import CoreGraphics

nonisolated struct NoseZones {
    var triggerScale: CGFloat = 1

    private let nose: CGPoint
    private let d: CGFloat
    private let axisU: CGPoint
    private let axisV: CGPoint
    private let eyeMid: CGPoint?
    private let lips: CGPoint?
    private let eyeZones: EyeZones?
    private let center: CGPoint

    init?(points: FacePoints) {
        guard let nose = points.nose, points.scale > 0 else { return nil }
        self.nose = nose
        self.d = points.scale
        self.lips = points.lips
        self.eyeZones = EyeZones(points: points)

        var u = CGPoint(x: 1, y: 0)
        var mid: CGPoint?
        if let l = points.leftEye, let r = points.rightEye {
            let len = hypot(r.x - l.x, r.y - l.y)
            if len > 0 {
                u = CGPoint(x: (r.x - l.x) / len, y: (r.y - l.y) / len)
                mid = CGPoint(x: (l.x + r.x) / 2, y: (l.y + r.y) / 2)
            }
        }
        self.axisU = u
        self.axisV = CGPoint(x: -u.y, y: u.x)
        self.center = CGPoint(
            x: nose.x + (u.x * ZoomTuning.noseCenterOffsetX + (-u.y) * ZoomTuning.noseCenterOffsetY) * points.scale,
            y: nose.y + (u.y * ZoomTuning.noseCenterOffsetX + u.x * ZoomTuning.noseCenterOffsetY) * points.scale
        )
        self.eyeMid = mid
    }

    func owns(_ p: CGPoint) -> Bool {
        guard !isBelowLips(p, hold: false) else { return false }
        if let m = eyeMid, coord(p, from: m, axis: axisV) < ZoomTuning.noseTopLimit { return false }
        return abs(coord(p, from: nose, axis: axisU)) <= ZoomTuning.noseOwnHalfWidth
    }

    func inTrigger(_ p: CGPoint) -> Bool {
        inOval(p,
               rx: ZoomTuning.noseTriggerRadiusX * triggerScale,
               ry: ZoomTuning.noseTriggerRadiusY * triggerScale)
    }

    func holds(_ p: CGPoint) -> Bool {
        guard !isBelowLips(p, hold: true) else { return false }
        return inOval(p,
                      rx: ZoomTuning.noseTriggerRadiusX * ZoomTuning.noseHoldScale,
                      ry: ZoomTuning.noseTriggerRadiusY * ZoomTuning.noseHoldScale)
    }

    private func coord(_ p: CGPoint, from origin: CGPoint, axis: CGPoint) -> CGFloat {
        ((p.x - origin.x) * axis.x + (p.y - origin.y) * axis.y) / d
    }

    private func inOval(_ p: CGPoint, rx: CGFloat, ry: CGFloat) -> Bool {
        let a = coord(p, from: center, axis: axisU)
        let b = coord(p, from: center, axis: axisV)
        return hypot(a / rx, b / ry) < 1
    }

    private func isBelowLips(_ p: CGPoint, hold: Bool) -> Bool {
        if let eyeZones { return hold ? eyeZones.isLipsHoldSide(p) : eyeZones.isLipsSide(p) }
        guard let lips else { return false }
        return hypot(p.x - lips.x, p.y - lips.y) < hypot(p.x - nose.x, p.y - nose.y)
    }
}
