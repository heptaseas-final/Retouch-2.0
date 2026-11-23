import Foundation

nonisolated final class InstallTracker: @unchecked Sendable {
    private enum Key {
        static let installedAt = "analytics.installedAt"
        static let retentionDay = "analytics.retentionDay"
        static let launchDay = "analytics.launchDay"
        static let launchCount = "analytics.launchCount"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    var installedAt: Date? { defaults.object(forKey: Key.installedAt) as? Date }

    func launched(at now: Date) -> [AnalyticsEvent] {
        var events: [AnalyticsEvent] = []
        if installedAt == nil {
            defaults.set(now, forKey: Key.installedAt)
            events.append(.appInstalled(source: AnalyticsConfig.organicSource, installedAt: now))
        }
        countLaunch(at: now)
        return events
    }

    func mirrorSessionStarted(at now: Date) -> [AnalyticsEvent] {
        retentionCheck(hadMirrorSession: true, at: now)
    }

    func appBackgrounded(at now: Date) -> [AnalyticsEvent] {
        retentionCheck(hadMirrorSession: false, at: now)
    }

    private func retentionCheck(hadMirrorSession: Bool, at now: Date) -> [AnalyticsEvent] {
        let today = day(now)
        guard defaults.object(forKey: Key.retentionDay) as? Int != today else { return [] }
        defaults.set(today, forKey: Key.retentionDay)
        return [.dailyRetentionCheck(daysSinceInstall: max(0, today - day(installedAt ?? now)),
                                     hadMirrorSessionToday: hadMirrorSession,
                                     launchCountToday: launchCount(at: now))]
    }

    private func countLaunch(at now: Date) {
        let today = day(now)
        let previous = defaults.object(forKey: Key.launchDay) as? Int == today ? storedLaunchCount : 0
        defaults.set(today, forKey: Key.launchDay)
        defaults.set(previous + 1, forKey: Key.launchCount)
    }

    private func launchCount(at now: Date) -> Int {
        defaults.object(forKey: Key.launchDay) as? Int == day(now) ? storedLaunchCount : 0
    }

    private var storedLaunchCount: Int {
        defaults.object(forKey: Key.launchCount) as? Int ?? 0
    }

    private func day(_ date: Date) -> Int {
        calendar.ordinality(of: .day, in: .era, for: date) ?? 0
    }
}
