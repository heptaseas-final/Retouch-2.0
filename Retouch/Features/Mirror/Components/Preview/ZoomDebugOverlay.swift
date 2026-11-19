import SwiftUI

struct ZoomDebugOverlay: View {
    let store: ZoomStore
    var isEnabled = true

    var body: some View {
        if isEnabled {
            TimelineView(.animation(minimumInterval: DebugStyle.refreshInterval)) { _ in
                let tracking = store.tracking
                let zoom = store.zoomState
                Canvas { context, size in
                    paint(&context, size: size, tracking: tracking, zoom: zoom)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

private enum DebugStyle {
    static let refreshInterval = 1.0 / 30
    static let lineWidth: CGFloat = 1.5
    static let dash: [CGFloat] = [6, 4]
    static let ovalSteps = 36
    static let lineSpan: CGFloat = 1.4
    static let gapTop: CGFloat = 0.8
    static let lipsLineFallbackRatio: CGFloat = 0.5
    static let columnBottomFallback: CGFloat = 2
    static let tipRadius: CGFloat = 3
    static let checkRadius: CGFloat = 4
    static let handRadius: CGFloat = 8
    static let labelOffset: CGFloat = 16
    static let eye = Color.cyan
    static let grip = Color.mint
    static let hold = Color.yellow
    static let lips = Color.pink
    static let nose = Color.orange
    static let gap = Color.gray
    static let tip = Color.white.opacity(0.7)
    static let handIdle = Color.white
    static let handPose = Color.green
    static let handGrip = Color.mint
    static let handPoint = Color.red
}

private struct DebugAxes {
    let zones: EyeZones
    let mid: CGPoint
    let u: CGPoint
    let v: CGPoint
    let d: CGFloat
    let lineT: CGFloat?
}

private struct DebugScene {
    let transform: CGAffineTransform
    let face: FacePoints
}

private extension ZoomDebugOverlay {
    func paint(_ context: inout GraphicsContext, size: CGSize, tracking: ZoomTracking, zoom: ZoomState) {
        let view = tracking.viewSize
        guard view.width > 0, view.height > 0 else { return }
        context.scaleBy(x: size.width / view.width, y: size.height / view.height)
        let center = CGPoint(x: view.width / 2, y: view.height / 2)
        let scale = max(zoom.scale, 0.01)
        let transform = CGAffineTransform(translationX: center.x + zoom.offset.width, y: center.y + zoom.offset.height)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -center.x, y: -center.y)
        let scene = DebugScene(transform: transform, face: tracking.face)
        let axes = axes(for: tracking.face)
        if let axes {
            drawEyes(&context, scene, axes)
            drawLips(&context, scene, axes)
            drawNose(&context, scene, axes)
            drawGaps(&context, scene, axes)
        }
        drawHands(&context, scene, axes, tracking)
    }

    func axes(for p: FacePoints) -> DebugAxes? {
        guard let l = p.leftEye, let r = p.rightEye, let zones = EyeZones(points: p) else { return nil }
        let mid = CGPoint(x: (l.x + r.x) / 2, y: (l.y + r.y) / 2)
        var line: CGFloat?
        if let top = p.lipsTop {
            line = zones.t(top) + ZoomTuning.lipsLineOffset
        } else if let lips = p.lips {
            line = zones.t(lips) * DebugStyle.lipsLineFallbackRatio
        }
        let lineT = line.flatMap { $0 > 0 ? $0 : nil }
        return DebugAxes(zones: zones, mid: mid, u: zones.axisU, v: zones.axisV, d: p.scale, lineT: lineT)
    }

    func place(_ a: DebugAxes, _ s: CGFloat, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.mid.x + (a.u.x * s + a.v.x * t) * a.d, y: a.mid.y + (a.u.y * s + a.v.y * t) * a.d)
    }

    func oval(at c: CGPoint, _ a: DebugAxes, rx: CGFloat, ry: CGFloat,
              outward: CGFloat = 0, outer: CGFloat = 1, inner: CGFloat = 1,
              up: CGFloat = 1, down: CGFloat = 1) -> Path {
        var path = Path()
        for i in 0...DebugStyle.ovalSteps {
            let angle = Double(i) / Double(DebugStyle.ovalSteps) * 2 * .pi
            let cosA = CGFloat(cos(angle)), sinA = CGFloat(sin(angle))
            let gain = outward == 0 ? 1 : (cosA * outward > 0 ? outer : inner)
            let gainY = sinA > 0 ? down : up
            let x = cosA * rx * gain, y = sinA * ry * gainY
            let point = CGPoint(x: c.x + a.u.x * x + a.v.x * y, y: c.y + a.u.y * x + a.v.y * y)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    func segment(_ from: CGPoint, _ to: CGPoint) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }

    func stroke(_ context: inout GraphicsContext, _ scene: DebugScene, _ path: Path, _ color: Color,
                dashed: Bool = false) {
        let style = StrokeStyle(lineWidth: DebugStyle.lineWidth, dash: dashed ? DebugStyle.dash : [])
        context.stroke(path.applying(scene.transform), with: .color(color), style: style)
    }

    func drawEyes(_ context: inout GraphicsContext, _ scene: DebugScene, _ a: DebugAxes) {
        let rx = ZoomTuning.eyeTriggerRadiusX * a.d, ry = ZoomTuning.eyeTriggerRadiusY * a.d
        let outer = ZoomTuning.eyeShapeOuter, inner = ZoomTuning.eyeShapeInner
        let up = ZoomTuning.eyeShapeUp, down = ZoomTuning.eyeShapeDown
        let sides: [(CGPoint?, CGFloat)] = [(scene.face.leftEye, -1), (scene.face.rightEye, 1)]
        for (eye, outward) in sides {
            guard let eye else { continue }
            stroke(&context, scene,
                   oval(at: eye, a, rx: rx, ry: ry, outward: outward, outer: outer, inner: inner, up: up, down: down),
                   DebugStyle.eye)
            stroke(&context, scene,
                   oval(at: eye, a, rx: rx, ry: ry * ZoomTuning.eyeGripScaleY, outward: outward,
                        outer: outer * ZoomTuning.eyeGripScaleOuter, inner: inner * ZoomTuning.eyeGripScaleInner,
                        up: up, down: down),
                   DebugStyle.grip)
            stroke(&context, scene,
                   oval(at: eye, a, rx: rx * ZoomTuning.eyeHoldScale, ry: ry * ZoomTuning.eyeHoldScale,
                        outward: outward, outer: outer, inner: inner, up: up, down: down),
                   DebugStyle.hold, dashed: true)
        }
    }

    func drawLips(_ context: inout GraphicsContext, _ scene: DebugScene, _ a: DebugAxes) {
        let p = scene.face
        if let lips = p.lips, p.width > 0 {
            let limit = CGFloat(ZoomTuning.handEnterDistance)
            let rx = limit * ZoomTuning.lipsTriggerStretchX * p.width
            let ry = limit * ZoomTuning.lipsTriggerStretchY * p.width
            stroke(&context, scene, oval(at: lips, a, rx: rx, ry: ry), DebugStyle.lips)
            stroke(&context, scene,
                   oval(at: lips, a, rx: rx * ZoomTuning.lipsHoldScale, ry: ry * ZoomTuning.lipsHoldScale),
                   DebugStyle.lips, dashed: true)
        }
        guard let line = a.lineT else { return }
        let span = DebugStyle.lineSpan
        stroke(&context, scene, segment(place(a, -span, line), place(a, span, line)), DebugStyle.lips)
    }

    func drawNose(_ context: inout GraphicsContext, _ scene: DebugScene, _ a: DebugAxes) {
        guard let nose = scene.face.nose else { return }
        let center = a.zones.s(nose)
        let top = ZoomTuning.noseColumnTop
        let line = a.lineT ?? DebugStyle.columnBottomFallback
        let halfGap = a.lineT == nil ? 0 : ZoomTuning.zoneGap / 2
        let columns: [(CGFloat, CGFloat, Bool)] = [
            (1, line - halfGap, false),
            (ZoomTuning.noseHoldScale, line, true)
        ]
        for (gain, end, dashed) in columns where end > top {
            let half = ZoomTuning.noseColumnHalfWidth * gain
            var path = Path()
            path.move(to: place(a, center - half, top))
            path.addLine(to: place(a, center + half, top))
            path.addLine(to: place(a, center + half, end))
            path.addLine(to: place(a, center - half, end))
            path.closeSubpath()
            stroke(&context, scene, path, DebugStyle.nose, dashed: dashed)
        }
    }

    func drawGaps(_ context: inout GraphicsContext, _ scene: DebugScene, _ a: DebugAxes) {
        let half = ZoomTuning.zoneGap / 2
        let bottom = a.lineT ?? DebugStyle.columnBottomFallback
        for edge in [-half, half] {
            stroke(&context, scene,
                   segment(place(a, edge, -DebugStyle.gapTop), place(a, edge, bottom)),
                   DebugStyle.gap, dashed: true)
        }
        guard let line = a.lineT else { return }
        let span = DebugStyle.lineSpan
        for edge in [line - half, line + half] {
            stroke(&context, scene, segment(place(a, -span, edge), place(a, span, edge)),
                   DebugStyle.gap, dashed: true)
        }
    }

    func drawHands(_ context: inout GraphicsContext, _ scene: DebugScene, _ a: DebugAxes?,
                   _ tracking: ZoomTracking) {
        for tip in tracking.fingertips {
            dot(&context, scene, tip, radius: DebugStyle.tipRadius, color: DebugStyle.tip)
        }
        for hand in tracking.hands {
            let color = handColor(hand)
            for p in hand.checkPoints {
                dot(&context, scene, p, radius: DebugStyle.checkRadius, color: color)
            }
            dot(&context, scene, hand.point, radius: DebugStyle.handRadius, color: color)
            label(&context, scene, hand.point, zoneName(of: hand.point, a, tracking.face), color)
        }
    }

    func handColor(_ hand: ZoomDebugHand) -> Color {
        if hand.isPoint { return DebugStyle.handPoint }
        if hand.isHolding { return DebugStyle.handGrip }
        if hand.hasPose { return DebugStyle.handPose }
        return DebugStyle.handIdle
    }

    func dot(_ context: inout GraphicsContext, _ scene: DebugScene, _ p: CGPoint, radius: CGFloat, color: Color) {
        let c = p.applying(scene.transform)
        let rect = CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    func label(_ context: inout GraphicsContext, _ scene: DebugScene, _ p: CGPoint, _ text: String, _ color: Color) {
        let c = p.applying(scene.transform)
        context.draw(Text(text).font(.caption2.bold()).foregroundColor(color),
                     at: CGPoint(x: c.x, y: c.y - DebugStyle.labelOffset))
    }

    func zoneName(of p: CGPoint, _ a: DebugAxes?, _ face: FacePoints) -> String {
        guard let a else { return "-" }
        if a.zones.isLipsSide(p) { return inLipsOval(p, a, face) ? "lips" : "gap" }
        if let side = a.zones.gripTriggerEye(at: p) ?? a.zones.triggerEye(at: p) {
            return side == .left ? "L" : "R"
        }
        if let nose = NoseZones(points: face), nose.inTrigger(p) { return "nose" }
        return "gap"
    }

    func inLipsOval(_ p: CGPoint, _ a: DebugAxes, _ face: FacePoints) -> Bool {
        guard let lips = face.lips, face.width > 0 else { return false }
        let limit = CGFloat(ZoomTuning.handEnterDistance)
        let rx = limit * ZoomTuning.lipsTriggerStretchX
        let ry = limit * ZoomTuning.lipsTriggerStretchY
        let dx = p.x - lips.x, dy = p.y - lips.y
        let x = (dx * a.u.x + dy * a.u.y) / face.width
        let y = (dx * a.v.x + dy * a.v.y) / face.width
        return hypot(x / rx, y / ry) < 1
    }
}
