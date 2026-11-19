import Foundation
@testable import Retouch

final class FakeAnalyticsSink: AnalyticsSink, @unchecked Sendable {
    private(set) var sent: [(name: String, properties: [String: AnalyticsValue])] = []
    private(set) var enabledCalls: [Bool] = []

    func send(name: String, properties: [String: AnalyticsValue]) {
        sent.append((name, properties))
    }

    func setEnabled(_ isEnabled: Bool) {
        enabledCalls.append(isEnabled)
    }
}
