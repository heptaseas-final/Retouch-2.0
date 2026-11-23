import Foundation
import Testing
@testable import Retouch

struct PerformanceHealthTrackerTests {
    private func sample(_ state: AnalyticsThermalState, battery: Double? = 0.80,
                        length: Int? = 60) -> PerformanceHealthSample {
        PerformanceHealthSample(thermalState: state, batteryLevel: battery, sessionLengthSeconds: length)
    }

    @Test func firstSampleReportsABaseline() {
        var tracker = PerformanceHealthTracker()
        let events = tracker.update(sample(.nominal))
        #expect(events.map(\.name) == ["performance_health_event"])
        #expect(events.first?.properties["thermal_state"] == .string("nominal"))
        #expect(events.first?.properties["session_length_seconds"] == .int(60))
    }

    @Test func unchangedThermalStateReportsNothing() {
        var tracker = PerformanceHealthTracker()
        _ = tracker.update(sample(.nominal))
        #expect(tracker.update(sample(.nominal)).isEmpty)
    }

    @Test func thermalChangeReportsAgain() {
        var tracker = PerformanceHealthTracker()
        _ = tracker.update(sample(.nominal))
        #expect(tracker.update(sample(.serious)).map(\.name) == ["performance_health_event"])
    }

    @Test func batteryImpactIsTheDropSinceTheFirstSample() {
        var tracker = PerformanceHealthTracker()
        _ = tracker.update(sample(.nominal, battery: 0.80))
        let events = tracker.update(sample(.fair, battery: 0.74))
        let impact = events.first?.properties["battery_impact_level"]
        guard case let .double(value) = impact else {
            Issue.record("battery_impact_level missing")
            return
        }
        #expect(abs(value - 6) < 0.001)
    }

    @Test func chargingDoesNotReportANegativeImpact() {
        var tracker = PerformanceHealthTracker()
        _ = tracker.update(sample(.nominal, battery: 0.50))
        #expect(tracker.update(sample(.fair, battery: 0.90)).first?.properties["battery_impact_level"] == .double(0))
    }

    @Test func unreadableBatteryIsOmitted() {
        var tracker = PerformanceHealthTracker()
        let events = tracker.update(sample(.nominal, battery: nil))
        #expect(events.first?.properties["battery_impact_level"] == nil)
    }

    @Test func resetClearsTheBaseline() {
        var tracker = PerformanceHealthTracker()
        _ = tracker.update(sample(.nominal))
        tracker.reset()
        #expect(tracker.update(sample(.nominal)).map(\.name) == ["performance_health_event"])
    }
}
