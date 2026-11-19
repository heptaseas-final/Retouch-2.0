import SwiftUI

struct ZoomDebugOverlay: View {
    let store: ZoomStore
    var isEnabled = true
    @State private var smoother = DebugFaceSmoother()

    var body: some View {
        if isEnabled {
            TimelineView(.animation(minimumInterval: DebugStyle.refreshInterval)) { timeline in
                let tracking = store.tracking
                let zoom = store.zoomState
                let face = smoother.follow(tracking.face, now: timeline.date)
                Canvas { context, size in
                    paint(&context, size: size, tracking: tracking, face: face, zoom: zoom)
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
    static let followTau = 0.08
    static let maxStep = 0.25
    static let cell: CGFloat = 6
    static let spanX: CGFloat = 0.8
    static let spanUp: CGFloat = 0.7
    static let spanDown: CGFloat = 1.0
    static let fill = 0.22
    static let lockedFill = 0.4
    static let anchorRadius: CGFloat = 2
    static let tipRadius: CGFloat = 3
    static let checkRadius: CGFloat = 4
    static let handRadius: CGFloat = 8
    static let toolRadius: CGFloat = 7
    static let labelOffset: CGFloat = 16
    static let modeLabelY: CGFloat = 0.12
    static let eye = Color.cyan
    static let nose = Color.orange
    static let lips = Color.pink
    static let anchor = Color.white.opacity(0.8)
    static let tip = Color.white.opacity(0.7)
    static let tool = Color.yellow
    static let handIdle = Color.white
    static let handPose = Color.green
    static let handGrip = Color.mint
    static let handPoint = Color.red
}

private final class DebugFaceSmoother {
    private var face = FacePoints()
    private var time: Date?

    func follow(_ target: FacePoints, now: Date) -> FacePoints {
        guard let last = time, face.width > 0, target.width > 0 else {
            face = target
            time = now
            return face
        }
        time = now
        let dt = min(max(now.timeIntervalSince(last), 0), DebugStyle.maxStep)
        let k = CGFloat(1 - exp(-dt / DebugStyle.followTau))
        face.leftEye = blend(face.leftEye, target.leftEye, k)
        face.rightEye = blend(face.rightEye, target.rightEye, k)
        face.nose = blend(face.nose, target.nose, k)
        face.lips = blend(face.lips, target.lips, k)
        face.lipsTop = blend(face.lipsTop, target.lipsTop, k)
        face.center = blend(face.center, target.center, k)
        face.width += (target.width - face.width) * k
        face.scale += (target.scale - face.scale) * k
        return face
    }

    private func blend(_ old: CGPoint?, _ new: CGPoint?, _ k: CGFloat) -> CGPoint? {
        guard let new else { return nil }
        guard let old else { return new }
        return CGPoint(x: old.x + (new.x - old.x) * k, y: old.y + (new.y - old.y) * k)
    }
}

private extension ZoomDebugOverlay {
    func paint(_ context: inout GraphicsContext, size: CGSize, tracking: ZoomTracking,
               face: FacePoints, zoom: ZoomState) {
        let view = tracking.viewSize
        guard view.width > 0, view.height > 0 else { return }
        context.scaleBy(x: size.width / view.width, y: size.height / view.height)
        let center = CGPoint(x: view.width / 2, y: view.height / 2)
        let scale = max(zoom.scale, 0.01)
        let transform = CGAffineTransform(translationX: center.x + zoom.offset.width, y: center.y + zoom.offset.height)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -center.x, y: -center.y)
        let map = FaceZoneMap(points: face, reach: tracking.zoneReach, lipsReach: tracking.lipsReach)
        if let map {
            drawZones(&context, view: view, transform: transform, map: map, face: face,
                      locked: tracking.lockedZone)
        }
        drawAnchors(&context, transform, face)
        drawHands(&context, transform, map, tracking)
        drawTools(&context, transform, map, tracking)
        drawMode(&context, view: view, mode: tracking.inputMode)
    }

    func drawMode(_ context: inout GraphicsContext, view: CGSize, mode: InputMode) {
        let text = mode == .tool ? "mode: alat" : "mode: jari"
        let color = mode == .tool ? DebugStyle.tool : DebugStyle.handPoint
        context.draw(Text(text).font(.caption.bold()).foregroundStyle(color),
                     at: CGPoint(x: view.width / 2, y: view.height * DebugStyle.modeLabelY))
    }

    func drawZones(_ context: inout GraphicsContext, view: CGSize, transform: CGAffineTransform,
                   map: FaceZoneMap, face: FacePoints, locked: FaceZone?) {
        guard let anchor = face.center ?? face.nose, face.width > 0 else { return }
        let w = face.width
        let source = CGRect(x: anchor.x - w * DebugStyle.spanX, y: anchor.y - w * DebugStyle.spanUp,
                            width: w * DebugStyle.spanX * 2, height: w * (DebugStyle.spanUp + DebugStyle.spanDown))
        let area = source.applying(transform).intersection(CGRect(origin: .zero, size: view))
        guard !area.isNull, !area.isEmpty else { return }
        let inverse = transform.inverted()
        let step = DebugStyle.cell
        var paths: [FaceZone: Path] = [:]
        var y = area.minY
        while y < area.maxY {
            var run: (zone: FaceZone, start: CGFloat)?
            var x = area.minX
            while x < area.maxX {
                let p = CGPoint(x: x + step / 2, y: y + step / 2).applying(inverse)
                let zone = map.zone(of: p, locked: locked)
                if run?.zone != zone {
                    if let run { paths[run.zone, default: Path()].addRect(CGRect(x: run.start, y: y, width: x - run.start, height: step)) }
                    run = zone.map { (zone: $0, start: x) }
                }
                x += step
            }
            if let run { paths[run.zone, default: Path()].addRect(CGRect(x: run.start, y: y, width: x - run.start, height: step)) }
            y += step
        }
        for (zone, path) in paths {
            let opacity = zone == locked ? DebugStyle.lockedFill : DebugStyle.fill
            context.fill(path, with: .color(color(of: zone).opacity(opacity)))
        }
    }

    func drawAnchors(_ context: inout GraphicsContext, _ transform: CGAffineTransform, _ face: FacePoints) {
        for p in [face.leftEye, face.rightEye, face.nose, face.lipsTop, face.lips].compactMap({ $0 }) {
            dot(&context, transform, p, radius: DebugStyle.anchorRadius, color: DebugStyle.anchor)
        }
    }

    func drawHands(_ context: inout GraphicsContext, _ transform: CGAffineTransform, _ map: FaceZoneMap?,
                   _ tracking: ZoomTracking) {
        for tip in tracking.fingertips {
            dot(&context, transform, tip, radius: DebugStyle.tipRadius, color: DebugStyle.tip)
        }
        for hand in tracking.hands {
            let color = handColor(hand)
            for p in hand.checkPoints {
                dot(&context, transform, p, radius: DebugStyle.checkRadius, color: color)
            }
            dot(&context, transform, hand.point, radius: DebugStyle.handRadius, color: color)
            label(&context, transform, hand.point, zoneName(hand.point, map, tracking.lockedZone), color)
        }
    }

    func drawTools(_ context: inout GraphicsContext, _ transform: CGAffineTransform, _ map: FaceZoneMap?,
                   _ tracking: ZoomTracking) {
        for tip in tracking.toolTips {
            dot(&context, transform, tip, radius: DebugStyle.toolRadius, color: DebugStyle.tool)
            label(&context, transform, tip, zoneName(tip, map, tracking.lockedZone), DebugStyle.tool)
        }
    }

    func color(of zone: FaceZone) -> Color {
        switch zone {
        case .leftEye, .rightEye: DebugStyle.eye
        case .nose: DebugStyle.nose
        case .lips: DebugStyle.lips
        }
    }

    func handColor(_ hand: ZoomDebugHand) -> Color {
        if hand.isPoint { return DebugStyle.handPoint }
        if hand.isHolding { return DebugStyle.handGrip }
        if hand.hasPose { return DebugStyle.handPose }
        return DebugStyle.handIdle
    }

    func zoneName(_ p: CGPoint, _ map: FaceZoneMap?, _ locked: FaceZone?) -> String {
        switch map?.zone(of: p, locked: locked) {
        case .leftEye: "L"
        case .rightEye: "R"
        case .nose: "nose"
        case .lips: "lips"
        case nil: "-"
        }
    }

    func dot(_ context: inout GraphicsContext, _ transform: CGAffineTransform, _ p: CGPoint,
             radius: CGFloat, color: Color) {
        let c = p.applying(transform)
        let rect = CGRect(x: c.x - radius, y: c.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    func label(_ context: inout GraphicsContext, _ transform: CGAffineTransform, _ p: CGPoint,
               _ text: String, _ color: Color) {
        let c = p.applying(transform)
        context.draw(Text(text).font(.caption2.bold()).foregroundStyle(color),
                     at: CGPoint(x: c.x, y: c.y - DebugStyle.labelOffset))
    }
}
