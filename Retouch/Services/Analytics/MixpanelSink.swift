import Foundation
import Mixpanel

nonisolated final class MixpanelSink: AnalyticsSink, @unchecked Sendable {
    private let instance: MixpanelInstance?

    init(bundle: Bundle = .main) {
        let token = bundle.object(forInfoDictionaryKey: AnalyticsConfig.tokenInfoKey) as? String
        guard let token, !token.isEmpty, !token.hasPrefix(AnalyticsConfig.unresolvedTokenPrefix) else {
            instance = nil
            return
        }
        let options = MixpanelOptions(token: token, trackAutomaticEvents: false)
        instance = Mixpanel.initialize(options: options)
    }

    func send(name: String, properties: [String: AnalyticsValue]) {
        instance?.track(event: name, properties: properties.mapValues(\.mixpanelValue))
    }

    func setEnabled(_ isEnabled: Bool) {
        if isEnabled {
            instance?.optInTracking()
        } else {
            instance?.optOutTracking()
        }
    }
}

private extension AnalyticsValue {
    var mixpanelValue: MixpanelType {
        switch self {
        case let .string(value): return value
        case let .int(value): return value
        case let .double(value): return value
        case let .bool(value): return value
        }
    }
}
