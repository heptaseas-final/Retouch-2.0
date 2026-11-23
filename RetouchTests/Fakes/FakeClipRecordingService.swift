import CoreGraphics
import CoreImage
@testable import Retouch

nonisolated final class FakeClipRecordingService: ClipRecordingServicing, @unchecked Sendable {
    var onEvent: (@Sendable (ClipRecordingEvent) -> Void)?
    private(set) var discarded: [RecordedClip] = []
    private(set) var enabledValues: [Bool] = []

    func setEnabled(_ isEnabled: Bool) { enabledValues.append(isEnabled) }
    func noteTracking(_ tracking: ZoomTracking) {}
    func finishRecording() {}
    func append(_ frame: CIImage, time: TimeInterval) {}
    func discard(_ clip: RecordedClip) { discarded.append(clip) }
    func thumbnail(for clip: RecordedClip) async -> CGImage? { nil }
}
