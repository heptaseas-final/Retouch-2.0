import Foundation

nonisolated final class AnalyticsConsentStore: @unchecked Sendable {
    private enum Key {
        static let isEnabled = "analytics.isEnabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isEnabled: Bool {
        get { defaults.object(forKey: Key.isEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.isEnabled) }
    }
}
