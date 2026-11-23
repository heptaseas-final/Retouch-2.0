import Foundation

nonisolated enum AnalyticsValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
}

nonisolated enum AnalyticsSessionEntry: String, Sendable {
    case coldLaunch = "cold_launch"
    case foreground
}

nonisolated enum AnalyticsSessionEndReason: String, Sendable, Codable {
    case background
    case noFace = "no_face"
}

nonisolated enum AnalyticsLightBucket: String, Sendable, Codable {
    case dark, dim, enough, good
    case veryBright = "very_bright"
}

nonisolated enum AnalyticsZoomTrigger: String, Sendable {
    case eye, lip, nose
    case headTurn = "head_turn"
}

nonisolated enum AnalyticsEyeSide: String, Sendable {
    case right, left
}

nonisolated enum AnalyticsShortcutGuideSource: String, Sendable {
    case prompt, settings
}

nonisolated enum AnalyticsOnboardingEntry: String, Sendable {
    case firstLaunch = "first_launch"
    case settings
}

nonisolated enum AnalyticsZoomMode: String, Sendable, Codable {
    case auto
    case lockRightEye = "lock_right_eye"
    case lockLeftEye = "lock_left_eye"
    case lockMouth = "lock_mouth"
    case lockNose = "lock_nose"
    case lockFullFace = "lock_full_face"
}

nonisolated enum AnalyticsLightColor: String, Sendable {
    case white, warm, cool
}

nonisolated enum AnalyticsThermalState: String, Sendable {
    case nominal, fair, serious, critical
}

nonisolated enum AnalyticsEvent: Sendable, Equatable {
    case appInstalled(source: String, installedAt: Date)
    case dailyRetentionCheck(daysSinceInstall: Int, hadMirrorSessionToday: Bool, launchCountToday: Int)
    case performanceHealth(thermalState: AnalyticsThermalState, batteryImpactLevel: Double?,
                           sessionLengthSeconds: Int?)
    case sessionStarted(sessionId: String, entry: AnalyticsSessionEntry, lightBucket: AnalyticsLightBucket,
                        startedAt: Date, initialMode: AnalyticsZoomMode)
    case sessionEnded(AnalyticsSessionSummary)
    case mirrorOpened(launchMs: Int)
    case cameraPermissionResult(isGranted: Bool)
    case cameraInterrupted(recoveryMs: Int)
    case onboardingStarted(variant: String, entry: AnalyticsOnboardingEntry)
    case onboardingStepCompleted(step: String, stepIndex: Int, secondsSinceStart: Int)
    case onboardingSkipped(step: String)
    case onboardingCompleted(completionTimeSeconds: Int, completedStepCount: Int)
    case replayTutorialOpened(replayCount: Int, sessionLengthSeconds: Int)
    case autoZoomTriggered(trigger: AnalyticsZoomTrigger, eyeSide: AnalyticsEyeSide?, holdMs: Int)
    case zoomModeChanged(from: AnalyticsZoomMode, to: AnalyticsZoomMode, secondsInPreviousMode: Int,
                         secondsSinceLastAutoZoom: Int?, lastAutoTrigger: AnalyticsZoomTrigger?,
                         positionsPassed: Int, settleMs: Int)
    case pinchZoomUsed(zoomLevel: Double)
    case lightChanged(color: AnalyticsLightColor)
    case autoLightResumed
    case autoLightAdjusted(msToTarget: Int, faceLuxBefore: Int, faceLuxAfter: Int, glowLevel: Double)
    case dimBannerShown(faceLux: Int)
    case lightGoodShown(faceLux: Int)
    case thermalStateChanged(state: AnalyticsThermalState)
    case glowLimitedByHeat
    case shortcutPromptShown
    case shortcutGuideOpened(source: AnalyticsShortcutGuideSource)
    case shortcutPromptDismissedForever
}

extension AnalyticsEvent {
    var name: String {
        switch self {
        case .appInstalled: "app_installed"
        case .dailyRetentionCheck: "daily_retention_check"
        case .performanceHealth: "performance_health_event"
        case .sessionStarted: "session_started"
        case .sessionEnded: "session_ended"
        case .mirrorOpened: "mirror_opened"
        case .cameraPermissionResult: "camera_permission_result"
        case .cameraInterrupted: "camera_interrupted"
        case .onboardingStarted: "onboarding_started"
        case .onboardingStepCompleted: "onboarding_step_completed"
        case .onboardingSkipped: "onboarding_skipped"
        case .onboardingCompleted: "onboarding_completed"
        case .replayTutorialOpened: "replay_tutorial_opened"
        case .autoZoomTriggered: "auto_zoom_triggered"
        case .zoomModeChanged: "zoom_mode_changed"
        case .pinchZoomUsed: "pinch_zoom_used"
        case .lightChanged: "light_changed"
        case .autoLightResumed: "auto_light_resumed"
        case .autoLightAdjusted: "auto_light_adjusted"
        case .dimBannerShown: "dim_banner_shown"
        case .lightGoodShown: "light_good_shown"
        case .thermalStateChanged: "thermal_state_changed"
        case .glowLimitedByHeat: "glow_limited_by_heat"
        case .shortcutPromptShown: "shortcut_prompt_shown"
        case .shortcutGuideOpened: "shortcut_guide_opened"
        case .shortcutPromptDismissedForever: "shortcut_prompt_dismissed_forever"
        }
    }

    var occurredAt: Date? {
        if case let .sessionEnded(summary) = self { return summary.endedAt }
        return nil
    }

    var properties: [String: AnalyticsValue] {
        switch self {
        case let .appInstalled(source, installedAt):
            return ["source": .string(source), "install_datetime": .string(Self.iso8601(installedAt))]
        case let .dailyRetentionCheck(daysSinceInstall, hadMirrorSessionToday, launchCountToday):
            return ["days_since_install": .int(daysSinceInstall),
                    "had_mirror_session_today": .bool(hadMirrorSessionToday),
                    "launch_count_today": .int(launchCountToday)]
        case let .performanceHealth(thermalState, batteryImpactLevel, sessionLengthSeconds):
            var values: [String: AnalyticsValue] = ["thermal_state": .string(thermalState.rawValue)]
            if let batteryImpactLevel { values["battery_impact_level"] = .double(batteryImpactLevel) }
            if let sessionLengthSeconds { values["session_length_seconds"] = .int(sessionLengthSeconds) }
            return values
        case let .sessionStarted(sessionId, entry, lightBucket, startedAt, initialMode):
            return ["session_id": .string(sessionId),
                    "entry": .string(entry.rawValue),
                    "light_bucket_at_start": .string(lightBucket.rawValue),
                    "session_start_datetime": .string(Self.iso8601(startedAt)),
                    "initial_mode": .string(initialMode.rawValue)]
        case let .sessionEnded(summary):
            return summary.properties
        case let .mirrorOpened(launchMs):
            return ["launch_ms": .int(launchMs)]
        case let .cameraPermissionResult(isGranted):
            return ["result": .string(isGranted ? "granted" : "denied")]
        case let .cameraInterrupted(recoveryMs):
            return ["recovery_ms": .int(recoveryMs)]
        case let .onboardingStarted(variant, entry):
            return ["onboarding_variant": .string(variant), "entry_method": .string(entry.rawValue)]
        case let .onboardingStepCompleted(step, stepIndex, secondsSinceStart):
            return ["step": .string(step),
                    "step_index": .int(stepIndex),
                    "time_since_onboarding_start_seconds": .int(secondsSinceStart)]
        case let .onboardingSkipped(step):
            return ["step": .string(step)]
        case let .onboardingCompleted(completionTimeSeconds, completedStepCount):
            return ["completion_time_seconds": .int(completionTimeSeconds),
                    "completed_step_count": .int(completedStepCount)]
        case let .replayTutorialOpened(replayCount, sessionLengthSeconds):
            return ["replay_count": .int(replayCount), "session_length_seconds": .int(sessionLengthSeconds)]
        case .autoLightResumed, .glowLimitedByHeat, .shortcutPromptShown, .shortcutPromptDismissedForever:
            return [:]
        case let .shortcutGuideOpened(source):
            return ["source": .string(source.rawValue)]
        case let .autoZoomTriggered(trigger, eyeSide, holdMs):
            var values: [String: AnalyticsValue] = ["trigger": .string(trigger.rawValue), "hold_ms": .int(holdMs)]
            if let eyeSide { values["eye_side"] = .string(eyeSide.rawValue) }
            return values
        case let .zoomModeChanged(from, to, secondsInPreviousMode, secondsSinceLastAutoZoom,
                                  lastAutoTrigger, positionsPassed, settleMs):
            var values: [String: AnalyticsValue] = [
                "from_mode": .string(from.rawValue),
                "to_mode": .string(to.rawValue),
                "seconds_in_previous_mode": .int(secondsInPreviousMode),
                "positions_passed": .int(positionsPassed),
                "settle_ms": .int(settleMs)
            ]
            if let secondsSinceLastAutoZoom { values["seconds_since_last_auto_zoom"] = .int(secondsSinceLastAutoZoom) }
            if let lastAutoTrigger { values["last_auto_trigger"] = .string(lastAutoTrigger.rawValue) }
            return values
        case let .pinchZoomUsed(zoomLevel):
            return ["zoom_level": .double(zoomLevel)]
        case let .lightChanged(color):
            return ["light_color": .string(color.rawValue)]
        case let .autoLightAdjusted(msToTarget, faceLuxBefore, faceLuxAfter, glowLevel):
            return ["ms_to_target": .int(msToTarget), "face_lux_before": .int(faceLuxBefore),
                    "face_lux_after": .int(faceLuxAfter), "glow_level": .double(glowLevel)]
        case let .dimBannerShown(faceLux), let .lightGoodShown(faceLux):
            return ["face_lux": .int(faceLux)]
        case let .thermalStateChanged(state):
            return ["state": .string(state.rawValue)]
        }
    }

    static func iso8601(_ date: Date) -> String {
        date.formatted(.iso8601)
    }
}
