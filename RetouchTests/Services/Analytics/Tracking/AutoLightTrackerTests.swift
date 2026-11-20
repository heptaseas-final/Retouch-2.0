import Foundation
import Testing
@testable import Retouch

@MainActor
struct AutoLightTrackerTests {
    private let origin = Date(timeIntervalSinceReferenceDate: 0)

    private func at(_ seconds: TimeInterval) -> Date {
        origin.addingTimeInterval(seconds)
    }

    private func sample(lux: Double? = 100, glow: Double = 0, isAuto: Bool = true, atMax: Bool = false) -> AutoLightSample {
        AutoLightSample(faceLux: lux, glowLevel: glow, isAuto: isAuto, isGlowAtMax: atMax)
    }

    private func dimTracker() -> AutoLightTracker {
        var tracker = AutoLightTracker()
        _ = tracker.update(sample(lux: 100), at: at(0))
        return tracker
    }

    @Test func reportsWhenFaceLuxReachesTarget() {
        var tracker = dimTracker()
        #expect(tracker.update(sample(lux: 180, glow: 0.2), at: at(10)).isEmpty)
        let events = tracker.update(sample(lux: 520, glow: 0.5), at: at(11.2))
        #expect(events == [.autoLightAdjusted(msToTarget: 1200, faceLuxBefore: 100, faceLuxAfter: 520, glowLevel: 0.5)])
    }

    @Test func reportsWhenGlowReachesMaxBelowTarget() {
        var tracker = dimTracker()
        _ = tracker.update(sample(lux: 150, glow: 0.3), at: at(10))
        let events = tracker.update(sample(lux: 280, glow: 1, atMax: true), at: at(12))
        #expect(events == [.autoLightAdjusted(msToTarget: 2000, faceLuxBefore: 100, faceLuxAfter: 280, glowLevel: 1)])
    }

    @Test func brightRoomReportsNothing() {
        var tracker = AutoLightTracker()
        #expect(tracker.update(sample(lux: 800), at: at(0)).isEmpty)
        #expect(tracker.update(sample(lux: 800), at: at(5)).isEmpty)
    }

    @Test func manualLightCancelsTheEpisode() {
        var tracker = dimTracker()
        _ = tracker.update(sample(lux: 150, glow: 0.3), at: at(10))
        #expect(tracker.update(sample(lux: 150, glow: 0.6, isAuto: false), at: at(11)).isEmpty)
        #expect(tracker.update(sample(lux: 600, glow: 0.6), at: at(12)).isEmpty)
    }

    @Test func lostFaceCancelsTheEpisode() {
        var tracker = dimTracker()
        _ = tracker.update(sample(lux: 150, glow: 0.3), at: at(10))
        #expect(tracker.update(sample(lux: nil, glow: 0.3), at: at(11)).isEmpty)
        #expect(tracker.update(sample(lux: 600, glow: 0.3), at: at(12)).isEmpty)
    }

    @Test func nextEpisodeNeedsGlowToTurnOffFirst() {
        var tracker = dimTracker()
        _ = tracker.update(sample(lux: 150, glow: 0.3), at: at(10))
        #expect(tracker.update(sample(lux: 520, glow: 0.5), at: at(11)).count == 1)
        #expect(tracker.update(sample(lux: 450, glow: 0.5), at: at(12)).isEmpty)
        #expect(tracker.update(sample(lux: 520, glow: 0.6), at: at(13)).isEmpty)
        _ = tracker.update(sample(lux: 90, glow: 0), at: at(20))
        _ = tracker.update(sample(lux: 130, glow: 0.2), at: at(21))
        #expect(tracker.update(sample(lux: 510, glow: 0.4), at: at(22)).count == 1)
    }

    @Test func resetClearsAnEpisodeInProgress() {
        var tracker = dimTracker()
        _ = tracker.update(sample(lux: 150, glow: 0.3), at: at(10))
        tracker.reset()
        #expect(tracker.update(sample(lux: 150, glow: 0.3), at: at(11)).isEmpty)
        let events = tracker.update(sample(lux: 520, glow: 0.4), at: at(12))
        #expect(events == [.autoLightAdjusted(msToTarget: 1000, faceLuxBefore: 150, faceLuxAfter: 520, glowLevel: 0.4)])
    }
}
