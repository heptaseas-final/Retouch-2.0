import Foundation

nonisolated struct ClipTrigger {
    enum Action: Equatable {
        case none, start, stop
    }

    var startDelay: TimeInterval = RecordingConfig.startDelay
    var stopDelay: TimeInterval = RecordingConfig.stopDelay

    private(set) var isRecording = false
    private var isArmed = false
    private var faceMissingSince: TimeInterval?
    private var faceReturnedAt: TimeInterval?

    mutating func update(isOverall: Bool, isFaceVisible: Bool, canStart: Bool, now: TimeInterval) -> Action {
        guard isRecording else {
            if isFaceVisible {
                isArmed = true
                faceMissingSince = nil
                return .none
            }
            guard isArmed, isOverall, canStart else {
                faceMissingSince = nil
                return .none
            }
            let missingSince = faceMissingSince ?? now
            faceMissingSince = missingSince
            guard now - missingSince >= startDelay else { return .none }
            isRecording = true
            isArmed = false
            faceMissingSince = nil
            faceReturnedAt = nil
            return .start
        }
        guard isFaceVisible else {
            faceReturnedAt = nil
            return .none
        }
        let returnedAt = faceReturnedAt ?? now
        faceReturnedAt = returnedAt
        guard now - returnedAt >= stopDelay else { return .none }
        isRecording = false
        faceReturnedAt = nil
        return .stop
    }

    mutating func recordingEnded() {
        isRecording = false
        isArmed = false
        faceMissingSince = nil
        faceReturnedAt = nil
    }
}
