import Foundation
import Testing
@testable import Retouch

struct AnalyticsServiceTests {
    private let context = AnalyticsContext(appVersion: "2.1", buildType: .testflight,
                                           iosVersion: "18.2.0", deviceModel: "iPhone16,1")

    private func makeConsent(isEnabled: Bool = true) throws -> AnalyticsConsentStore {
        let name = "AnalyticsServiceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        let consent = AnalyticsConsentStore(defaults: defaults)
        consent.isEnabled = isEnabled
        return consent
    }

    @Test func trackSendsNameWithContextAndEventProperties() throws {
        let sink = FakeAnalyticsSink()
        let service = AnalyticsService(sink: sink, context: context, consent: try makeConsent())
        service.track(.autoZoomTriggered(trigger: .eye, eyeSide: .left, holdMs: 1200))
        let sent = try #require(sink.sent.first)
        #expect(sent.name == "auto_zoom_triggered")
        #expect(sent.properties["trigger"] == .string("eye"))
        #expect(sent.properties["hold_ms"] == .int(1200))
        #expect(sent.properties["app_version"] == .string("2.1"))
        #expect(sent.properties["build_type"] == .string("testflight"))
        #expect(sent.properties["ios_version"] == .string("18.2.0"))
        #expect(sent.properties["device_model"] == .string("iPhone16,1"))
        #expect(sent.properties["local_hour"] != nil)
        #expect(sent.properties["weekday"] != nil)
        #expect(sent.properties["utc_offset"] != nil)
    }

    @Test func eventPropertyWinsOverContextOnTheSameKey() throws {
        let sink = FakeAnalyticsSink()
        let service = AnalyticsService(sink: sink, context: context, consent: try makeConsent())
        service.track(.thermalStateChanged(state: .serious))
        let sent = try #require(sink.sent.first)
        #expect(sent.properties["state"] == .string("serious"))
        #expect(sent.properties["build_type"] == .string("testflight"))
    }

    @Test func trackSendsNothingWhenOptedOut() throws {
        let sink = FakeAnalyticsSink()
        let service = AnalyticsService(sink: sink, context: context, consent: try makeConsent(isEnabled: false))
        service.track(.onboardingCompleted(completionTimeSeconds: 0, completedStepCount: 0))
        #expect(sink.sent.isEmpty)
    }

    @Test func setEnabledStoresChoiceAndTellsSink() throws {
        let sink = FakeAnalyticsSink()
        let service = AnalyticsService(sink: sink, context: context, consent: try makeConsent())
        service.setEnabled(false)
        #expect(!service.isEnabled)
        service.track(.onboardingCompleted(completionTimeSeconds: 0, completedStepCount: 0))
        #expect(sink.sent.isEmpty)
        service.setEnabled(true)
        #expect(service.isEnabled)
        service.track(.onboardingCompleted(completionTimeSeconds: 0, completedStepCount: 0))
        #expect(sink.sent.count == 1)
        #expect(sink.enabledCalls == [false, true])
    }

    @Test func storedOptOutIsAppliedToSinkAtInit() throws {
        let sink = FakeAnalyticsSink()
        _ = AnalyticsService(sink: sink, context: context, consent: try makeConsent(isEnabled: false))
        #expect(sink.enabledCalls == [false])
    }

    @Test func enabledConsentLeavesSinkUntouchedAtInit() throws {
        let sink = FakeAnalyticsSink()
        _ = AnalyticsService(sink: sink, context: context, consent: try makeConsent())
        #expect(sink.enabledCalls.isEmpty)
    }
}
