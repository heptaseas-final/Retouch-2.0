import Testing
@testable import Retouch

struct ClipTriggerTests {
    @Test func startsWhenPlacedBegins() {
        var trigger = ClipTrigger()
        #expect(trigger.update(pose: .none, canStart: true) == .none)
        #expect(trigger.update(pose: .placedFar, canStart: true) == .start)
        #expect(trigger.isRecording)
    }

    @Test func keepsRecordingWhilePlaced() {
        var trigger = ClipTrigger()
        _ = trigger.update(pose: .placedFar, canStart: true)
        #expect(trigger.update(pose: .placedFar, canStart: true) == .none)
        #expect(trigger.isRecording)
    }

    @Test func stopsWhenPlacedEnds() {
        var trigger = ClipTrigger()
        _ = trigger.update(pose: .placedFar, canStart: true)
        #expect(trigger.update(pose: .none, canStart: true) == .stop)
        #expect(!trigger.isRecording)
    }

    @Test func heldHighNeverRecords() {
        var trigger = ClipTrigger()
        #expect(trigger.update(pose: .heldHigh, canStart: true) == .none)
        #expect(trigger.update(pose: .heldHigh, canStart: true) == .none)
    }

    @Test func noRestartAfterMaxDurationUntilUserComesBack() {
        var trigger = ClipTrigger()
        _ = trigger.update(pose: .placedFar, canStart: true)
        trigger.recordingEnded()
        #expect(trigger.update(pose: .placedFar, canStart: true) == .none)
        _ = trigger.update(pose: .none, canStart: true)
        #expect(trigger.update(pose: .placedFar, canStart: true) == .start)
    }

    @Test func hotPhoneDoesNotStart() {
        var trigger = ClipTrigger()
        #expect(trigger.update(pose: .placedFar, canStart: false) == .none)
    }

    @Test func maxDurationIsTenSeconds() {
        #expect(RecordingConfig.maxDuration == 10)
    }
}
