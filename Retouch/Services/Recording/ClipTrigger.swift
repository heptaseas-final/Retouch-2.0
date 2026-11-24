import Foundation

nonisolated struct ClipTrigger {
    enum Action: Equatable {
        case none, start, stop
    }

    private(set) var isRecording = false
    private var waitsForComeBack = false

    mutating func update(pose: OverallPose, isRecordFar: Bool, canStart: Bool) -> Action {
        let isFar = pose == .placedFar && isRecordFar
        if !isFar { waitsForComeBack = false }
        if isRecording {
            guard !isFar else { return .none }
            isRecording = false
            return .stop
        }
        guard isFar, !waitsForComeBack, canStart else { return .none }
        isRecording = true
        waitsForComeBack = true
        return .start
    }

    mutating func recordingEnded() {
        isRecording = false
    }
}
