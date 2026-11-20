import Foundation

nonisolated struct ClipTrigger {
    enum Action: Equatable {
        case none, start, stop
    }

    private(set) var isRecording = false
    private var wasPlaced = false

    mutating func update(pose: OverallPose, canStart: Bool) -> Action {
        let isPlaced = pose == .placedFar
        defer { wasPlaced = isPlaced }
        if isRecording {
            guard !isPlaced else { return .none }
            isRecording = false
            return .stop
        }
        guard isPlaced, !wasPlaced, canStart else { return .none }
        isRecording = true
        return .start
    }

    mutating func recordingEnded() {
        isRecording = false
    }
}
