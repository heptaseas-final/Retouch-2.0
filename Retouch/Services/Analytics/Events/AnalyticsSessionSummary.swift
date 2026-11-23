import Foundation

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
    var sessionId = ""
    var pinchZooms = 0
    var overallChecks = 0
    var nightModeAvailable = false
}

extension AnalyticsSessionSummary {
    var gestureZooms: Int { eyeZooms + lipZooms + noseZooms + headTurnZooms }

    var manualZooms: Int {
        pinchZooms + lockRightEyeUses + lockLeftEyeUses + lockMouthUses + lockNoseUses + lockFullFaceUses
    }

    var featureBundle: [String] {
        var features: [String] = []
        if gestureZooms > 0 { features.append("gesture_zoom") }
        if manualZooms > 0 { features.append("manual_zoom") }
        if overallChecks > 0 { features.append("overall_check") }
        if nightModeAvailable { features.append("night_mode") }
        return features
    }

    var properties: [String: AnalyticsValue] {
        var values: [String: AnalyticsValue] = [
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
        values["session_id"] = .string(sessionId)
        values["pinch_zooms"] = .int(pinchZooms)
        values["overall_checks"] = .int(overallChecks)
        values["night_mode_available"] = .bool(nightModeAvailable)
        values["feature_bundle"] = .string(featureBundle.joined(separator: ","))
        return values
    }
}
