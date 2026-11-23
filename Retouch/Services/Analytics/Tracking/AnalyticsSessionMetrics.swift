import Foundation

nonisolated struct AnalyticsSample {
    var hasFace: Bool
    var target: ZoomTarget
    var zoomScale: Double
    var faceLux: Double?
    var isGlowAtMax: Bool
    var isNightModeEnabled = false
}

nonisolated enum AnalyticsSessionMetrics {
    static func zoom(for target: ZoomTarget) -> (trigger: AnalyticsZoomTrigger, eyeSide: AnalyticsEyeSide?)? {
        switch target {
        case .fullFace, .overall: return nil
        case .leftEye: return (.eye, .left)
        case .rightEye: return (.eye, .right)
        case .lips: return (.lip, nil)
        case .nose: return (.nose, nil)
        case .faceSide, .cheek: return (.headTurn, nil)
        }
    }

    static func seconds(_ interval: TimeInterval) -> Int {
        Int(max(0, interval).rounded())
    }

    static func milliseconds(_ interval: TimeInterval) -> Int {
        Int((max(0, interval) * AnalyticsConfig.millisecondsPerSecond).rounded())
    }
}
