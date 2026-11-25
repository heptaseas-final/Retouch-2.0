import Testing
@testable import Retouch

struct ClipTriggerTests {
    @Test func zoomOutAloneDoesNotRecord() {
        var trigger = ClipTrigger()
        #expect(trigger.update(pose: .placedFar, isRecordFar: false, canStart: true) == .none)
        #expect(!trigger.isRecording)
    }

    @Test func startsWhenFartherThanZoomOut() {
        var trigger = ClipTrigger()
        #expect(trigger.update(pose: .none, isRecordFar: false, canStart: true) == .none)
        #expect(trigger.update(pose: .placedFar, isRecordFar: false, canStart: true) == .none)
        #expect(trigger.update(pose: .placedFar, isRecordFar: true, canStart: true) == .start)
        #expect(trigger.isRecording)
    }

    @Test func stopsWhenBackAtZoomOutDistance() {
        var trigger = ClipTrigger()
        _ = trigger.update(pose: .placedFar, isRecordFar: true, canStart: true)
        #expect(trigger.update(pose: .placedFar, isRecordFar: false, canStart: true) == .stop)
        #expect(!trigger.isRecording)
    }

    @Test func recordsAgainAfterComingBackAndMovingFarAgain() {
        var trigger = ClipTrigger()
        _ = trigger.update(pose: .placedFar, isRecordFar: true, canStart: true)
        _ = trigger.update(pose: .placedFar, isRecordFar: false, canStart: true)
        #expect(trigger.update(pose: .placedFar, isRecordFar: true, canStart: true) == .start)
    }

    @Test func stopsWhenZoomOutEnds() {
        var trigger = ClipTrigger()
        _ = trigger.update(pose: .placedFar, isRecordFar: true, canStart: true)
        #expect(trigger.update(pose: .none, isRecordFar: false, canStart: true) == .stop)
        #expect(!trigger.isRecording)
    }

    @Test func heldHighNeverRecords() {
        var trigger = ClipTrigger()
        #expect(trigger.update(pose: .heldHigh, isRecordFar: true, canStart: true) == .none)
        #expect(trigger.update(pose: .heldHigh, isRecordFar: true, canStart: true) == .none)
    }

    @Test func noRestartAfterMaxDurationUntilUserComesBack() {
        var trigger = ClipTrigger()
        _ = trigger.update(pose: .placedFar, isRecordFar: true, canStart: true)
        trigger.recordingEnded()
        #expect(trigger.update(pose: .placedFar, isRecordFar: true, canStart: true) == .none)
        #expect(trigger.update(pose: .placedFar, isRecordFar: false, canStart: true) == .none)
        #expect(trigger.update(pose: .placedFar, isRecordFar: true, canStart: true) == .start)
    }

    @Test func hotPhoneDoesNotStart() {
        var trigger = ClipTrigger()
        #expect(trigger.update(pose: .placedFar, isRecordFar: true, canStart: false) == .none)
    }

    @Test func maxDurationIsFifteenSeconds() {
        #expect(RecordingConfig.maxDuration == 15)
    }
}
