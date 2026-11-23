import Foundation

nonisolated enum AnalyticsConfig {
    static let tokenInfoKey = "MixpanelToken"

    static let faceSeenToStartSession: TimeInterval = 10
    static let sessionEndTimeout: TimeInterval = 60
    static let likelyFalseZoomWindow: TimeInterval = 5
    static let faceLostGrace: TimeInterval = 1
    static let settleTolerance = 0.05
    static let settleTimeout: TimeInterval = 2
    static let millisecondsPerSecond = 1000.0
    static let pollInterval: Duration = .milliseconds(250)
    static let unresolvedTokenPrefix = "$("
    static let sandboxReceiptName = "sandboxReceipt"
    static let unknownValue = "unknown"
    static let organicSource = "organic"
    static let onboardingVariant = "default"
    static let batteryImpactScale = 100.0
    static let secondsPerHour = 3600.0

    static let glowStartLevel = 0.01

    static let darkLuxLimit = 30.0
    static let dimLuxLimit = 300.0
    static let enoughLuxLimit = 500.0
    static let goodLuxLimit = 1000.0
}
