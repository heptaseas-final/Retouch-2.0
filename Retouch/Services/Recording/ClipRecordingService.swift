import AVFoundation
import CoreImage

nonisolated struct RecordedClip: Equatable, Identifiable, Sendable {
    let url: URL
    let duration: TimeInterval

    var id: URL { url }
}

nonisolated enum ClipRecordingEvent: Sendable {
    case started
    case finished(RecordedClip)
    case cancelled
}

nonisolated protocol ClipRecordingServicing: AnyObject, Sendable {
    var onEvent: (@Sendable (ClipRecordingEvent) -> Void)? { get set }
    func setEnabled(_ isEnabled: Bool)
    func noteTracking(_ tracking: ZoomTracking)
    func finishRecording()
    func append(_ frame: CIImage, time: TimeInterval)
    func discard(_ clip: RecordedClip)
    func thumbnail(for clip: RecordedClip) async -> CGImage?
}

nonisolated final class ClipRecordingService: ClipRecordingServicing, @unchecked Sendable {
    var onEvent: (@Sendable (ClipRecordingEvent) -> Void)? {
        get { lock.withLock { eventHandler } }
        set { lock.withLock { eventHandler = newValue } }
    }

    private let writer: ClipWriter
    private let lock = NSLock()
    private var eventHandler: (@Sendable (ClipRecordingEvent) -> Void)?
    private var trigger = ClipTrigger()
    private var isEnabled = false

    init(writer: ClipWriter) {
        self.writer = writer
    }

    func setEnabled(_ isEnabled: Bool) {
        let cancelsRecording = lock.withLock {
            let wasRecording = trigger.isRecording
            self.isEnabled = isEnabled
            if !isEnabled { trigger = ClipTrigger() }
            return wasRecording && !isEnabled
        }
        guard cancelsRecording else { return }
        writer.cancel()
        onEvent?(.cancelled)
    }

    func noteTracking(_ tracking: ZoomTracking) {
        let canStart = ProcessInfo.processInfo.thermalState.rawValue < ProcessInfo.ThermalState.serious.rawValue
        let action = lock.withLock { () -> ClipTrigger.Action in
            guard isEnabled else { return .none }
            return trigger.update(pose: tracking.overallPose, isRecordFar: tracking.isRecordFar, canStart: canStart)
        }
        switch action {
        case .none:
            break
        case .start:
            writer.begin()
            onEvent?(.started)
        case .stop:
            finish()
        }
    }

    func finishRecording() {
        let wasRecording = lock.withLock { () -> Bool in
            let wasRecording = trigger.isRecording
            trigger.recordingEnded()
            return wasRecording
        }
        guard wasRecording else { return }
        finish()
    }

    func append(_ frame: CIImage, time: TimeInterval) {
        guard writer.append(frame, time: time) == .reachedLimit else { return }
        lock.withLock { trigger.recordingEnded() }
        finish()
    }

    func discard(_ clip: RecordedClip) {
        writer.delete(clip.url)
    }

    func thumbnail(for clip: RecordedClip) async -> CGImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: clip.url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = RecordingConfig.thumbnailPixelSize
        return try? await generator.image(at: .zero).image
    }

    private func finish() {
        Task { [weak self, writer] in
            let clip = await writer.finish()
            self?.onEvent?(clip.map { .finished($0) } ?? .cancelled)
        }
    }
}
