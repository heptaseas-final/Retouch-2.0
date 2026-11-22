import Testing
@testable import Retouch

@MainActor
struct ZoomOnboardingSignalsTests {
    let zoom = FakeZoomService()

    private func makeSignals() -> ZoomOnboardingSignals {
        ZoomOnboardingSignals(store: ZoomStore(), zoom: zoom, lighting: FakeLightingService())
    }

    @Test func overallOnlyIsForwardedToZoom() {
        let signals = makeSignals()
        signals.setOverallOnly(true)
        #expect(zoom.overallOnlyValues == [true])
    }

    @Test func resetTurnsOverallOnlyOff() {
        let signals = makeSignals()
        signals.setOverallOnly(true)
        signals.resetToDefaults()
        #expect(zoom.overallOnlyValues == [true, false])
        #expect(zoom.gestureEnabled == [true])
    }
}
