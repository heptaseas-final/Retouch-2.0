import Foundation
import Testing
@testable import Retouch

struct AnalyticsEventTests {
    private let summary = AnalyticsSessionSummary(startLocalHour: 10, startWeekday: 3, lengthSeconds: 120,
                                                  endReason: .background, lightBucket: .good,
                                                  endedAt: Date(timeIntervalSince1970: 1_794_884_400),
                                                  eyeZooms: 3, modeAtEnd: .lockMouth)

    private var allEvents: [AnalyticsEvent] {
        [
            .sessionStarted(entry: .coldLaunch, lightBucket: .dim),
            .sessionEnded(summary),
            .mirrorOpened(launchMs: 800),
            .cameraPermissionResult(isGranted: true),
            .cameraInterrupted(recoveryMs: 500),
            .onboardingStepCompleted(step: "place_hand"),
            .onboardingSkipped(step: "swipe_modes"),
            .onboardingCompleted,
            .replayTutorialOpened,
            .autoZoomTriggered(trigger: .lip, eyeSide: nil, holdMs: 900),
            .zoomModeChanged(from: .auto, to: .lockNose, secondsInPreviousMode: 12, secondsSinceLastAutoZoom: nil,
                             lastAutoTrigger: nil, positionsPassed: 2, settleMs: 300),
            .pinchZoomUsed(zoomLevel: 1.8),
            .lightChanged(color: .warm),
            .autoLightResumed,
            .autoLightAdjusted(msToTarget: 900, faceLuxBefore: 120, faceLuxAfter: 510, glowLevel: 0.6),
            .dimBannerShown(faceLux: 80),
            .lightGoodShown(faceLux: 520),
            .thermalStateChanged(state: .fair),
            .glowLimitedByHeat,
            .shortcutPromptShown,
            .shortcutGuideOpened(source: .prompt),
            .shortcutPromptDismissedForever
        ]
    }

    @Test func everyEventHasAUniqueSnakeCaseName() {
        let names = allEvents.map(\.name)
        #expect(Set(names).count == names.count)
        for name in names {
            #expect(name.allSatisfy { $0.isLowercase || $0 == "_" })
        }
    }

    @Test func eventsWithoutPropertiesStayEmpty() {
        #expect(AnalyticsEvent.onboardingCompleted.properties.isEmpty)
        #expect(AnalyticsEvent.replayTutorialOpened.properties.isEmpty)
        #expect(AnalyticsEvent.autoLightResumed.properties.isEmpty)
        #expect(AnalyticsEvent.glowLimitedByHeat.properties.isEmpty)
        #expect(AnalyticsEvent.shortcutPromptShown.properties.isEmpty)
        #expect(AnalyticsEvent.shortcutPromptDismissedForever.properties.isEmpty)
        #expect(AnalyticsEvent.shortcutGuideOpened(source: .settings).properties["source"] == .string("settings"))
    }

    @Test func autoZoomOmitsEyeSideWhenThereIsNone() {
        let lips = AnalyticsEvent.autoZoomTriggered(trigger: .lip, eyeSide: nil, holdMs: 900).properties
        #expect(lips["trigger"] == .string("lip"))
        #expect(lips["hold_ms"] == .int(900))
        #expect(lips["eye_side"] == nil)
        let eye = AnalyticsEvent.autoZoomTriggered(trigger: .eye, eyeSide: .right, holdMs: 400).properties
        #expect(eye["eye_side"] == .string("right"))
    }

    @Test func zoomModeChangeAddsAutoOnlyFieldsWhenPresent() {
        let fromLock = AnalyticsEvent.zoomModeChanged(from: .lockMouth, to: .auto, secondsInPreviousMode: 30,
                                                      secondsSinceLastAutoZoom: nil, lastAutoTrigger: nil,
                                                      positionsPassed: 3, settleMs: 450).properties
        #expect(fromLock["from_mode"] == .string("lock_mouth"))
        #expect(fromLock["to_mode"] == .string("auto"))
        #expect(fromLock["positions_passed"] == .int(3))
        #expect(fromLock["settle_ms"] == .int(450))
        #expect(fromLock["seconds_since_last_auto_zoom"] == nil)
        #expect(fromLock["last_auto_trigger"] == nil)
        let fromAuto = AnalyticsEvent.zoomModeChanged(from: .auto, to: .lockLeftEye, secondsInPreviousMode: 12,
                                                      secondsSinceLastAutoZoom: 4, lastAutoTrigger: .headTurn,
                                                      positionsPassed: 1, settleMs: 200).properties
        #expect(fromAuto["seconds_since_last_auto_zoom"] == .int(4))
        #expect(fromAuto["last_auto_trigger"] == .string("head_turn"))
    }

    @Test func sessionEndedCarriesTheSummary() {
        let properties = AnalyticsEvent.sessionEnded(summary).properties
        #expect(properties["session_length_s"] == .int(120))
        #expect(properties["end_reason"] == .string("background"))
        #expect(properties["light_bucket"] == .string("good"))
        #expect(properties["eye_zooms"] == .int(3))
        #expect(properties["glow_max_reached"] == .bool(false))
        #expect(properties["mode_at_end"] == .string("lock_mouth"))
    }

    @Test func occurredAtIsOnlySetForSessionEnded() {
        #expect(AnalyticsEvent.sessionEnded(summary).occurredAt == summary.endedAt)
        #expect(AnalyticsEvent.onboardingCompleted.occurredAt == nil)
    }

    @Test func permissionResultIsGrantedOrDenied() {
        #expect(AnalyticsEvent.cameraPermissionResult(isGranted: true).properties["result"] == .string("granted"))
        #expect(AnalyticsEvent.cameraPermissionResult(isGranted: false).properties["result"] == .string("denied"))
    }

    @Test func lightEventsCarryTheirNumbers() {
        let adjusted = AnalyticsEvent.autoLightAdjusted(msToTarget: 900, faceLuxBefore: 120,
                                                        faceLuxAfter: 510, glowLevel: 0.6).properties
        #expect(adjusted["ms_to_target"] == .int(900))
        #expect(adjusted["face_lux_before"] == .int(120))
        #expect(adjusted["face_lux_after"] == .int(510))
        #expect(adjusted["glow_level"] == .double(0.6))
        #expect(AnalyticsEvent.lightChanged(color: .cool).properties["light_color"] == .string("cool"))
        #expect(AnalyticsEvent.dimBannerShown(faceLux: 80).properties["face_lux"] == .int(80))
    }
}
