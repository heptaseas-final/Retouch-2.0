import Foundation
import Testing
@testable import Retouch

@MainActor
struct AnalyticsSessionTrackerTests {
    private let origin = Date(timeIntervalSinceReferenceDate: 0)

    private func at(_ seconds: TimeInterval) -> Date {
        origin.addingTimeInterval(seconds)
    }

    private func sample(hasFace: Bool = true, target: ZoomTarget = .fullFace, scale: Double = 1.1,
                        lux: Double? = 600, glowAtMax: Bool = false) -> AnalyticsSample {
        AnalyticsSample(hasFace: hasFace, target: target, zoomScale: scale, faceLux: lux, isGlowAtMax: glowAtMax)
    }

    private func startedTracker() -> AnalyticsSessionTracker {
        var tracker = AnalyticsSessionTracker(launchStartedAt: origin)
        _ = tracker.update(sample(), at: at(0))
        _ = tracker.update(sample(), at: at(10))
        return tracker
    }

    private func summary(in events: [AnalyticsEvent]) -> AnalyticsSessionSummary? {
        for event in events {
            if case let .sessionEnded(summary) = event { return summary }
        }
        return nil
    }

    @Test func sessionStartsAfterFaceSeenForTenSeconds() {
        var tracker = AnalyticsSessionTracker(launchStartedAt: origin)
        #expect(tracker.update(sample(), at: at(0)).isEmpty)
        #expect(tracker.update(sample(), at: at(9)).isEmpty)
        #expect(tracker.update(sample(), at: at(10)) == [.sessionStarted(entry: .coldLaunch, lightBucket: .good)])
    }

    @Test func backgroundEndsSessionAndNextSessionIsForeground() {
        var tracker = startedTracker()
        _ = tracker.update(sample(), at: at(20))
        let ended = summary(in: tracker.appBackgrounded(at: at(30)))
        #expect(ended?.endReason == .background)
        #expect(ended?.lengthSeconds == 20)
        tracker.appForegrounded()
        _ = tracker.update(sample(), at: at(40))
        #expect(tracker.update(sample(), at: at(50)) == [.sessionStarted(entry: .foreground, lightBucket: .good)])
    }

    @Test func noFaceEndsSessionAtLastFaceSeen() {
        var tracker = startedTracker()
        _ = tracker.update(sample(), at: at(15))
        #expect(tracker.update(sample(hasFace: false), at: at(74)).isEmpty)
        let ended = summary(in: tracker.update(sample(hasFace: false), at: at(75)))
        #expect(ended?.endReason == .noFace)
        #expect(ended?.endedAt == at(15))
        #expect(ended?.lengthSeconds == 5)
    }

    @Test func autoZoomIsReportedOnReleaseWithHoldTime() {
        var tracker = startedTracker()
        #expect(tracker.update(sample(target: .rightEye, scale: 2.25), at: at(11)).isEmpty)
        let events = tracker.update(sample(), at: at(14))
        #expect(events == [.autoZoomTriggered(trigger: .eye, eyeSide: .right, holdMs: 3000)])
        let ended = summary(in: tracker.appBackgrounded(at: at(20)))
        #expect(ended?.eyeZooms == 1)
        #expect(ended?.likelyFalseZooms == 1)
    }

    @Test func longZoomIsNotLikelyFalse() {
        var tracker = startedTracker()
        _ = tracker.update(sample(target: .lips, scale: 2.12), at: at(11))
        _ = tracker.update(sample(), at: at(19))
        let ended = summary(in: tracker.appBackgrounded(at: at(20)))
        #expect(ended?.lipZooms == 1)
        #expect(ended?.likelyFalseZooms == 0)
    }

    @Test func lockedModeReportsSettleTimeAndNoAutoZoom() {
        var tracker = startedTracker()
        #expect(tracker.partChanged(from: .face, to: .leftEye, at: at(11)).isEmpty)
        let scale = Double(ZoomTarget.leftEye.zoomScale)
        let events = tracker.update(sample(target: .leftEye, scale: scale), at: at(12))
        #expect(events == [.zoomModeChanged(from: .auto, to: .lockLeftEye, secondsInPreviousMode: 11,
                                            secondsSinceLastAutoZoom: nil, lastAutoTrigger: nil,
                                            positionsPassed: 2, settleMs: 1000)])
    }

    @Test func returningToAutoIgnoresStaleLockedTarget() {
        var tracker = startedTracker()
        _ = tracker.partChanged(from: .face, to: .leftEye, at: at(11))
        _ = tracker.update(sample(target: .leftEye, scale: Double(ZoomTarget.leftEye.zoomScale)), at: at(12))
        _ = tracker.partChanged(from: .leftEye, to: .face, at: at(20))
        #expect(tracker.update(sample(target: .leftEye, scale: 2.25), at: at(20.1)).isEmpty)
        let events = tracker.update(sample(), at: at(20.5))
        #expect(events.count == 1)
        #expect(events.first?.name == "zoom_mode_changed")
    }

    @Test func modeChangesAreCountedInSummary() {
        var tracker = startedTracker()
        _ = tracker.partChanged(from: .face, to: .nose, at: at(11))
        _ = tracker.partChanged(from: .nose, to: .face, at: at(12))
        let ended = summary(in: tracker.appBackgrounded(at: at(20)))
        #expect(ended?.modeChanges == 2)
        #expect(ended?.lockNoseUses == 1)
        #expect(ended?.modeAtEnd == .auto)
    }

    @Test func pickerPositionsWrapAround() {
        #expect(AnalyticsSessionTracker.positions(from: .leftEye, to: .smile) == 1)
        #expect(AnalyticsSessionTracker.positions(from: .face, to: .face) == 0)
    }

    @Test func dominantLightBucketAndTimeInAutoAreSummarised() {
        var tracker = startedTracker()
        _ = tracker.update(sample(lux: 100), at: at(20))
        _ = tracker.update(sample(lux: 100), at: at(50))
        let ended = summary(in: tracker.appBackgrounded(at: at(50)))
        #expect(ended?.lightBucket == .dim)
        #expect(ended?.timeInAutoSeconds == 40)
        #expect(ended?.timeLockedSeconds == 0)
    }

    @Test func lightBucketBoundaries() {
        #expect(AnalyticsSessionTracker.bucket(for: 29.9) == .dark)
        #expect(AnalyticsSessionTracker.bucket(for: 30) == .dim)
        #expect(AnalyticsSessionTracker.bucket(for: 300) == .enough)
        #expect(AnalyticsSessionTracker.bucket(for: 500) == .good)
        #expect(AnalyticsSessionTracker.bucket(for: 1000) == .veryBright)
    }

    @Test func permissionResultIsReportedOnceAnswered() {
        var granted = AnalyticsSessionTracker(launchStartedAt: origin)
        #expect(granted.cameraStateChanged(from: .notDetermined, to: .starting, at: at(1)) == [.cameraPermissionResult(isGranted: true)])
        var denied = AnalyticsSessionTracker(launchStartedAt: origin)
        #expect(denied.cameraStateChanged(from: .notDetermined, to: .permissionDenied, at: at(1)) == [.cameraPermissionResult(isGranted: false)])
    }

    @Test func mirrorOpenedIsSkippedWhenPermissionPromptWasShown() {
        var tracker = AnalyticsSessionTracker(launchStartedAt: origin)
        _ = tracker.cameraStateChanged(from: .notDetermined, to: .starting, at: at(1))
        #expect(tracker.cameraStateChanged(from: .starting, to: .running, at: at(5)).isEmpty)
    }

    @Test func mirrorOpenedReportsLaunchTimeOnce() {
        var tracker = AnalyticsSessionTracker(launchStartedAt: origin)
        #expect(tracker.cameraStateChanged(from: .starting, to: .running, at: at(1.2)) == [.mirrorOpened(launchMs: 1200)])
        _ = tracker.cameraStateChanged(from: .running, to: .reconnecting, at: at(5))
        #expect(tracker.cameraStateChanged(from: .reconnecting, to: .running, at: at(5.4)) == [.cameraInterrupted(recoveryMs: 400)])
    }

    @Test func backgroundReconnectIsNotAnInterruption() {
        var tracker = AnalyticsSessionTracker(launchStartedAt: origin)
        _ = tracker.cameraStateChanged(from: .starting, to: .running, at: at(1))
        _ = tracker.appBackgrounded(at: at(5))
        _ = tracker.cameraStateChanged(from: .running, to: .reconnecting, at: at(5.1))
        tracker.appForegrounded()
        #expect(tracker.cameraStateChanged(from: .reconnecting, to: .running, at: at(20)).isEmpty)
    }
}
