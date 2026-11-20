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

nonisolated struct AnalyticsSessionSummary: Sendable, Equatable, Codable {
    var startLocalHour: Int
    var startWeekday: Int
    var lengthSeconds: Int
    var endReason: AnalyticsSessionEndReason
    var lightBucket: AnalyticsLightBucket
    var endedAt: Date
    var eyeZooms = 0
    var lipZooms = 0
    var headTurnZooms = 0
    var noseZooms = 0
    var zoomedTimeSeconds = 0
    var bannerShown = 0
    var glowMaxReached = false
    var modeChanges = 0
    var timeInAutoSeconds = 0
    var timeLockedSeconds = 0
    var lockRightEyeUses = 0
    var lockLeftEyeUses = 0
    var lockMouthUses = 0
    var lockNoseUses = 0
    var lockFullFaceUses = 0
    var likelyFalseZooms = 0
    var modeAtEnd: AnalyticsZoomMode = .auto
}

extension AnalyticsSessionSummary {
    var properties: [String: AnalyticsValue] {
        let values: [String: AnalyticsValue] = [
            "start_local_hour": .int(startLocalHour),
            "start_weekday": .int(startWeekday),
            "session_length_s": .int(lengthSeconds),
            "end_reason": .string(endReason.rawValue),
            "light_bucket": .string(lightBucket.rawValue),
            "eye_zooms": .int(eyeZooms),
            "lip_zooms": .int(lipZooms),
            "head_turn_zooms": .int(headTurnZooms),
            "nose_zooms": .int(noseZooms),
            "zoomed_time_s": .int(zoomedTimeSeconds),
            "banner_shown": .int(bannerShown),
            "glow_max_reached": .bool(glowMaxReached),
            "mode_changes": .int(modeChanges),
            "time_in_auto_s": .int(timeInAutoSeconds),
            "time_locked_s": .int(timeLockedSeconds),
            "lock_right_eye_uses": .int(lockRightEyeUses),
            "lock_left_eye_uses": .int(lockLeftEyeUses),
            "lock_mouth_uses": .int(lockMouthUses),
            "lock_nose_uses": .int(lockNoseUses),
            "lock_full_face_uses": .int(lockFullFaceUses),
            "likely_false_zooms": .int(likelyFalseZooms),
            "mode_at_end": .string(modeAtEnd.rawValue)
        ]
        return values
    }
}

nonisolated enum AnalyticsEvent: Sendable, Equatable {
    case sessionStarted(entry: AnalyticsSessionEntry, lightBucket: AnalyticsLightBucket)
    case sessionEnded(AnalyticsSessionSummary)
    case mirrorOpened(launchMs: Int)
    case cameraPermissionResult(isGranted: Bool)
    case cameraInterrupted(recoveryMs: Int)
    case onboardingStepCompleted(step: String)
    case onboardingSkipped(step: String)
    case onboardingCompleted
    case replayTutorialOpened
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
        case .sessionStarted: "session_started"
        case .sessionEnded: "session_ended"
        case .mirrorOpened: "mirror_opened"
        case .cameraPermissionResult: "camera_permission_result"
        case .cameraInterrupted: "camera_interrupted"
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
        case let .sessionStarted(entry, lightBucket):
            return ["entry": .string(entry.rawValue), "light_bucket_at_start": .string(lightBucket.rawValue)]
        case let .sessionEnded(summary):
            return summary.properties
        case let .mirrorOpened(launchMs):
            return ["launch_ms": .int(launchMs)]
        case let .cameraPermissionResult(isGranted):
            return ["result": .string(isGranted ? "granted" : "denied")]
        case let .cameraInterrupted(recoveryMs):
            return ["recovery_ms": .int(recoveryMs)]
        case let .onboardingStepCompleted(step), let .onboardingSkipped(step):
            return ["step": .string(step)]
        case .onboardingCompleted, .replayTutorialOpened, .autoLightResumed, .glowLimitedByHeat,
             .shortcutPromptShown, .shortcutPromptDismissedForever:
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
}
