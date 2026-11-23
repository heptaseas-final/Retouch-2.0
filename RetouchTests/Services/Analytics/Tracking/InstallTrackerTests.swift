import Foundation
import Testing
@testable import Retouch

struct InstallTrackerTests {
    private let origin = Date(timeIntervalSince1970: 1_794_884_400)
    private let oneDay = TimeInterval(86_400)

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private func makeTracker() throws -> InstallTracker {
        let name = "InstallTrackerTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        return InstallTracker(defaults: defaults, calendar: utc)
    }

    private func value(_ events: [AnalyticsEvent], _ key: String) -> AnalyticsValue? {
        events.first?.properties[key]
    }

    @Test func firstLaunchReportsInstallOnce() throws {
        let tracker = try makeTracker()
        let first = tracker.launched(at: origin)
        #expect(first.map(\.name) == ["app_installed"])
        #expect(value(first, "source") == .string("organic"))
        #expect(tracker.launched(at: origin.addingTimeInterval(60)).isEmpty)
    }

    @Test func installDateSurvivesLaterLaunches() throws {
        let tracker = try makeTracker()
        _ = tracker.launched(at: origin)
        _ = tracker.launched(at: origin.addingTimeInterval(oneDay))
        #expect(tracker.installedAt == origin)
    }

    @Test func retentionIsReportedOncePerDay() throws {
        let tracker = try makeTracker()
        _ = tracker.launched(at: origin)
        let first = tracker.mirrorSessionStarted(at: origin)
        #expect(first.map(\.name) == ["daily_retention_check"])
        #expect(value(first, "had_mirror_session_today") == .bool(true))
        #expect(tracker.mirrorSessionStarted(at: origin.addingTimeInterval(60)).isEmpty)
        #expect(tracker.appBackgrounded(at: origin.addingTimeInterval(120)).isEmpty)
    }

    @Test func retentionCountsDaysSinceInstall() throws {
        let tracker = try makeTracker()
        _ = tracker.launched(at: origin)
        let later = origin.addingTimeInterval(7 * oneDay)
        _ = tracker.launched(at: later)
        #expect(value(tracker.mirrorSessionStarted(at: later), "days_since_install") == .int(7))
    }

    @Test func backgroundReportsADayWithoutAMirrorSession() throws {
        let tracker = try makeTracker()
        _ = tracker.launched(at: origin)
        let events = tracker.appBackgrounded(at: origin.addingTimeInterval(60))
        #expect(events.map(\.name) == ["daily_retention_check"])
        #expect(value(events, "had_mirror_session_today") == .bool(false))
    }

    @Test func launchCountResetsOnANewDay() throws {
        let tracker = try makeTracker()
        _ = tracker.launched(at: origin)
        _ = tracker.launched(at: origin.addingTimeInterval(60))
        #expect(value(tracker.mirrorSessionStarted(at: origin), "launch_count_today") == .int(2))
        let nextDay = origin.addingTimeInterval(oneDay)
        _ = tracker.launched(at: nextDay)
        #expect(value(tracker.mirrorSessionStarted(at: nextDay), "launch_count_today") == .int(1))
    }
}
