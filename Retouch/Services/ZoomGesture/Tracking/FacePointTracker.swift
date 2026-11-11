import CoreGraphics
import Foundation

nonisolated struct FacePointTracker {
    var pointTau: CGFloat = ZoomTuning.pointTau
    var scaleTau: CGFloat = ZoomTuning.scaleTau
    var maxScaleYaw = 30.0
    private(set) var points = FacePoints()
    private var lastTime: Date?
    private var coverRef: (points: FacePoints, center: CGPoint, width: CGFloat)?

    mutating func update(face: FaceObservation?, covering: Bool, converter: CoordinateConverter,
                         now: Date) -> FacePoints {
        guard let face else { return points }
        if covering {
            followFaceBox(face: face, converter: converter, now: now)
            return points
        }
        coverRef = nil
        let dt = min(max(lastTime.map { now.timeIntervalSince($0) } ?? ZoomTuning.nominalStep, 0.001),
                     ZoomTuning.maxStep)
        lastTime = now
        let alpha = CGFloat(1 - exp(-dt / Double(pointTau)))
        points.leftEye = smooth(points.leftEye, face.leftEye.map(converter.toView), alpha)
        points.rightEye = smooth(points.rightEye, face.rightEye.map(converter.toView), alpha)
        points.lips = smooth(points.lips, face.lips.map(converter.toView), alpha)
        points.lipsTop = smooth(points.lipsTop, face.lipsTop.map(converter.toView), alpha)
        points.nose = smooth(points.nose, face.nose.map(converter.toView), alpha)
        points.center = smooth(points.center, converter.toView(face.center), alpha)
        learnWidth(face: face, converter: converter, dt: dt)
        learnScale(face: face, converter: converter, dt: dt)
        return points
    }

    private mutating func followFaceBox(face: FaceObservation, converter: CoordinateConverter, now: Date) {
        guard ZoomTuning.coverFollowEnabled else { return }
        let center = converter.toView(face.center)
        let width = converter.width(face.width)
        guard width > 0 else { return }
        guard let ref = coverRef else {
            coverRef = (points, center, width)
            lastTime = now
            return
        }
        guard ref.width > 0 else { return }

        let dt = min(max(lastTime.map { now.timeIntervalSince($0) } ?? ZoomTuning.nominalStep, 0.001),
                     ZoomTuning.maxStep)
        lastTime = now
        let alpha = CGFloat(1 - exp(-dt / Double(pointTau)))

        var k = width / ref.width
        if !(abs(face.yaw) < maxScaleYaw) { k = 1 }
        k = min(max(k, ZoomTuning.coverFollowMinScale), ZoomTuning.coverFollowMaxScale)

        func moved(_ p: CGPoint?) -> CGPoint? {
            guard let p else { return nil }
            return CGPoint(x: center.x + (p.x - ref.center.x) * k,
                           y: center.y + (p.y - ref.center.y) * k)
        }
        points.leftEye = smooth(points.leftEye, moved(ref.points.leftEye), alpha)
        points.rightEye = smooth(points.rightEye, moved(ref.points.rightEye), alpha)
        points.lips = smooth(points.lips, moved(ref.points.lips), alpha)
        points.lipsTop = smooth(points.lipsTop, moved(ref.points.lipsTop), alpha)
        points.nose = smooth(points.nose, moved(ref.points.nose), alpha)
        points.center = smooth(points.center, moved(ref.points.center), alpha)
        points.width += (ref.points.width * k - points.width) * alpha
        points.scale += (ref.points.scale * k - points.scale) * alpha
    }

    private mutating func learnWidth(face: FaceObservation, converter: CoordinateConverter, dt: TimeInterval) {
        let raw = converter.width(face.width)
        guard points.width > 0 else {
            points.width = raw
            return
        }
        guard abs(face.yaw) < maxScaleYaw else { return }
        let alpha = CGFloat(1 - exp(-dt / Double(ZoomTuning.widthTau)))
        points.width += (raw - points.width) * alpha
    }

    private mutating func learnScale(face: FaceObservation, converter: CoordinateConverter, dt: TimeInterval) {
        guard abs(face.yaw) < maxScaleYaw,
              let l = face.leftEye.map(converter.toView),
              let r = face.rightEye.map(converter.toView) else { return }
        let cosYaw = CGFloat(max(cos(face.yaw * .pi / 180), 0.6))
        let sample = hypot(l.x - r.x, l.y - r.y) / cosYaw
        let alpha = CGFloat(1 - exp(-dt / Double(scaleTau)))
        points.scale = points.scale == 0
            ? sample
            : points.scale + (sample - points.scale) * alpha
    }

    private func smooth(_ old: CGPoint?, _ new: CGPoint?, _ alpha: CGFloat) -> CGPoint? {
        guard let new else { return old }
        guard let old else { return new }
        return CGPoint(x: old.x + (new.x - old.x) * alpha,
                       y: old.y + (new.y - old.y) * alpha)
    }
}
