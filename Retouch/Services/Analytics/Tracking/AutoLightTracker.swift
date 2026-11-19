import Foundation

struct AutoLightSample {
    var faceLux: Double?
    var glowLevel: Double
    var isAuto: Bool
    var isGlowAtMax: Bool
}

struct AutoLightTracker {
    private struct Episode {
        var startedAt: Date
        var faceLuxBefore: Int
    }

    private var episode: Episode?
    private var luxBeforeGlow: Double?
    private var isArmed = true

    mutating func update(_ sample: AutoLightSample, at now: Date) -> [AnalyticsEvent] {
        guard sample.isAuto, let lux = sample.faceLux else {
            episode = nil
            return []
        }
        guard sample.glowLevel >= AnalyticsConfig.glowStartLevel else {
            luxBeforeGlow = lux
            episode = nil
            isArmed = true
            return []
        }
        if episode == nil {
            guard isArmed else { return [] }
            isArmed = false
            episode = Episode(startedAt: now, faceLuxBefore: Self.rounded(luxBeforeGlow ?? lux))
        }
        guard let active = episode, lux >= AnalyticsConfig.enoughLuxLimit || sample.isGlowAtMax else { return [] }
        episode = nil
        return [.autoLightAdjusted(msToTarget: Self.milliseconds(now.timeIntervalSince(active.startedAt)),
                                   faceLuxBefore: active.faceLuxBefore,
                                   faceLuxAfter: Self.rounded(lux),
                                   glowLevel: sample.glowLevel)]
    }

    mutating func reset() {
        self = AutoLightTracker()
    }

    private static func rounded(_ lux: Double) -> Int {
        lux.isFinite ? Int(lux.rounded()) : 0
    }

    private static func milliseconds(_ interval: TimeInterval) -> Int {
        Int((max(0, interval) * AnalyticsConfig.millisecondsPerSecond).rounded())
    }
}
