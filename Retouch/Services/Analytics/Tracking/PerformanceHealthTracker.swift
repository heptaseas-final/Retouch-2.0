import Foundation

nonisolated struct PerformanceHealthSample {
    var thermalState: AnalyticsThermalState
    var batteryLevel: Double?
    var sessionLengthSeconds: Int?
}

nonisolated struct PerformanceHealthTracker {
    private var lastThermalState: AnalyticsThermalState?
    private var batteryAtStart: Double?

    mutating func update(_ sample: PerformanceHealthSample) -> [AnalyticsEvent] {
        if batteryAtStart == nil, let level = sample.batteryLevel, level >= 0 { batteryAtStart = level }
        guard sample.thermalState != lastThermalState else { return [] }
        lastThermalState = sample.thermalState
        return [.performanceHealth(thermalState: sample.thermalState,
                                   batteryImpactLevel: impact(from: sample.batteryLevel),
                                   sessionLengthSeconds: sample.sessionLengthSeconds)]
    }

    mutating func reset() {
        self = PerformanceHealthTracker()
    }

    private func impact(from level: Double?) -> Double? {
        guard let level, level >= 0, let start = batteryAtStart else { return nil }
        return max(0, (start - level) * AnalyticsConfig.batteryImpactScale)
    }
}
