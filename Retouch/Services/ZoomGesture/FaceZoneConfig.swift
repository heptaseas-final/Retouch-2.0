import CoreGraphics
import Foundation

nonisolated struct FaceZonePoint: Sendable {
    let x: CGFloat
    let y: CGFloat
    let fromEdge: Bool

    static func at(_ x: CGFloat, _ y: CGFloat) -> FaceZonePoint {
        FaceZonePoint(x: x, y: y, fromEdge: false)
    }

    static func edge(_ x: CGFloat, _ y: CGFloat) -> FaceZonePoint {
        FaceZonePoint(x: x, y: y, fromEdge: true)
    }
}

nonisolated enum FaceZoneConfig {
    static let turnEnter: CGFloat = 0.09
    static let turnExit: CGFloat = 0.045
    static let turnDwell: TimeInterval = 0.4
    static let turnGrace: TimeInterval = 0.3

    static let defaultDepth: CGFloat = 1.05
    static let minDepth: CGFloat = 0.7
    static let maxDepth: CGFloat = 1.5
    static let defaultHalfWidth: CGFloat = 1.1
    static let frontalMinEdge: CGFloat = 1.0
    static let turnedMinEdge: CGFloat = 0.8

    static let frontalCheekEnabled = false
    static let layoutDrivesHeadZoom = true
    static let cheekFocusEdgeFraction: CGFloat = 0.6
    static let cheekFocusY: CGFloat = 1.0

    static func lockGrowth(for zone: FaceZone, layout: FaceZoneLayout) -> CGFloat {
        switch zone {
        case .leftEye, .rightEye: 1.4
        case .nose: layout == .frontal ? 1.3 : 1.6
        case .lips: 1.25
        case .leftCheek, .rightCheek: 1.15
        }
    }

    static func priority(of zone: FaceZone) -> Int {
        switch zone {
        case .leftEye, .rightEye: 0
        case .nose: 1
        case .lips: 2
        case .leftCheek, .rightCheek: 3
        }
    }

    static let frontalNose: [FaceZonePoint] = [
        .at(-0.16, -0.40), .at(0.16, -0.40), .at(0.20, -0.10), .at(0.26, 0.30),
        .at(0.42, 0.65), .at(0.42, 0.86), .at(-0.42, 0.86), .at(-0.42, 0.65),
        .at(-0.26, 0.30), .at(-0.20, -0.10)
    ]

    static let frontalEye: [FaceZonePoint] = [
        .at(0.16, -0.40), .at(0.30, -0.46), .at(0.60, -0.48), .at(0.88, -0.40),
        .at(0.95, -0.05), .at(0.90, 0.50), .at(0.35, 0.50), .at(0.26, 0.30),
        .at(0.20, -0.10)
    ]

    static let frontalLips: [FaceZonePoint] = [
        .at(-0.42, 0.86), .at(0.42, 0.86), .at(0.55, 1.02), .at(0.55, 1.28),
        .at(0.30, 1.45), .at(-0.30, 1.45), .at(-0.55, 1.28), .at(-0.55, 1.02)
    ]

    static let frontalCheek: [FaceZonePoint] = [
        .at(0.95, -0.05), .edge(0, -0.05), .edge(0, 1.10), .at(0.80, 1.55),
        .at(0.55, 1.28), .at(0.55, 1.02), .at(0.42, 0.86), .at(0.42, 0.65),
        .at(0.35, 0.50), .at(0.90, 0.50)
    ]

    static let turnedEye: [FaceZonePoint] = [
        .at(-0.40, -0.42), .at(0, -0.55), .at(0.40, -0.52), .at(0.62, -0.30),
        .at(0.65, 0.05), .at(0.55, 0.40), .at(0.20, 0.48), .at(-0.15, 0.45),
        .at(-0.28, 0.40), .at(-0.42, 0)
    ]

    static let turnedNose: [FaceZonePoint] = [
        .at(-0.40, -0.42), .at(-0.42, 0), .at(-0.28, 0.40), .at(-0.28, 0.72),
        .at(-0.70, 0.80), .at(-0.66, -0.42)
    ]

    static let turnedCheek: [FaceZonePoint] = [
        .at(0.40, -0.52), .edge(-0.05, -0.55), .edge(0, 0), .edge(0, 0.85),
        .edge(-0.10, 1.25), .at(0.15, 1.62), .at(-0.25, 1.50), .at(-0.28, 0.72),
        .at(-0.28, 0.40), .at(-0.15, 0.45), .at(0.20, 0.48), .at(0.55, 0.40),
        .at(0.65, 0.05), .at(0.62, -0.30)
    ]
}
