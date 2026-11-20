import Foundation

nonisolated protocol AnalyticsSink: Sendable {
    func send(name: String, properties: [String: AnalyticsValue])
    func setEnabled(_ isEnabled: Bool)
}

nonisolated protocol AnalyticsServicing: Sendable {
    var isEnabled: Bool { get }
    func setEnabled(_ isEnabled: Bool)
    func track(_ event: AnalyticsEvent)
}

nonisolated final class AnalyticsService: AnalyticsServicing, Sendable {
    private let sink: AnalyticsSink
    private let context: AnalyticsContext
    private let consent: AnalyticsConsentStore
    private let now: @Sendable () -> Date

    init(sink: AnalyticsSink, context: AnalyticsContext, consent: AnalyticsConsentStore,
         now: @escaping @Sendable () -> Date = { Date() }) {
        self.sink = sink
        self.context = context
        self.consent = consent
        self.now = now
        if !consent.isEnabled { sink.setEnabled(false) }
    }

    convenience init(bundle: Bundle = .main) {
        self.init(sink: MixpanelSink(bundle: bundle),
                  context: .current(bundle: bundle),
                  consent: AnalyticsConsentStore())
    }

    var isEnabled: Bool { consent.isEnabled }

    func setEnabled(_ isEnabled: Bool) {
        consent.isEnabled = isEnabled
        sink.setEnabled(isEnabled)
    }

    func track(_ event: AnalyticsEvent) {
        guard consent.isEnabled else { return }
        var properties = context.properties(at: now())
        properties.merge(event.properties) { _, eventValue in eventValue }
        sink.send(name: event.name, properties: properties)
    }
}
