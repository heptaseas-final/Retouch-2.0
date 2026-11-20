import Foundation

nonisolated struct ToolDetectionSchedule {
    struct Context {
        var isAutoZoom: Bool
        var faceVisible: Bool
        var handSeen: Bool
        var zoomHolding: Bool
        var thermalState: ProcessInfo.ThermalState
        var isLowPowerMode: Bool
    }

    private var lastToolSeen = Date.distantPast

    mutating func noteToolSeen(at now: Date) { lastToolSeen = now }

    func interval(_ context: Context, now: Date) -> TimeInterval? {
        guard context.isAutoZoom, context.faceVisible else { return nil }
        let throttled: Bool
        switch context.thermalState {
        case .nominal: throttled = context.isLowPowerMode
        case .fair: throttled = true
        default: return nil
        }
        let active = context.handSeen || context.zoomHolding
            || now.timeIntervalSince(lastToolSeen) < ToolDetectionTuning.keepActiveAfterSeen
        let rate: Double
        if active {
            rate = throttled ? ToolDetectionTuning.fairActiveRate : ToolDetectionTuning.activeRate
        } else {
            rate = throttled ? ToolDetectionTuning.fairProbeRate : ToolDetectionTuning.probeRate
        }
        return 1 / rate
    }
}
