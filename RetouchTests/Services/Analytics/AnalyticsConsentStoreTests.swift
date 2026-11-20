    import Foundation
import Testing
@testable import Retouch

struct AnalyticsConsentStoreTests {
    private func makeDefaults() throws -> UserDefaults {
        let name = "AnalyticsConsentStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func isEnabledByDefault() throws {
        let store = AnalyticsConsentStore(defaults: try makeDefaults())
        #expect(store.isEnabled)
    }

    @Test func storesOptOut() throws {
        let store = AnalyticsConsentStore(defaults: try makeDefaults())
        store.isEnabled = false
        #expect(!store.isEnabled)
    }

    @Test func optOutSurvivesANewInstance() throws {
        let defaults = try makeDefaults()
        AnalyticsConsentStore(defaults: defaults).isEnabled = false
        #expect(!AnalyticsConsentStore(defaults: defaults).isEnabled)
    }

    @Test func canOptBackIn() throws {
        let store = AnalyticsConsentStore(defaults: try makeDefaults())
        store.isEnabled = false
        store.isEnabled = true
        #expect(store.isEnabled)
    }
}
