import CoreGraphics
import Foundation
import Observation

enum ClipNotice: Equatable {
    case saved, photosDenied, saveFailed

    var message: String {
        switch self {
        case .saved: "Saved to Photos"
        case .photosDenied: "Allow Retouch to add to Photos in Settings to save clips."
        case .saveFailed: "Couldn't save the clip. Try again."
        }
    }
}

@Observable
final class ClipReviewViewModel {
    private(set) var isRecording = false
    private(set) var clip: RecordedClip?
    private(set) var thumbnail: CGImage?
    private(set) var previewClip: RecordedClip?
    private(set) var isSaving = false
    private(set) var notice: ClipNotice?

    @ObservationIgnored private let recording: ClipRecordingServicing
    @ObservationIgnored private let photos: PhotoLibraryServicing
    @ObservationIgnored private let camera: CameraServicing
    @ObservationIgnored private var isActive = false
    @ObservationIgnored private var dismissTask: Task<Void, Never>?
    @ObservationIgnored private var noticeTask: Task<Void, Never>?

    init(recording: ClipRecordingServicing, photos: PhotoLibraryServicing, camera: CameraServicing) {
        self.recording = recording
        self.photos = photos
        self.camera = camera
        recording.onEvent = { [weak self] event in
            Task { @MainActor [weak self] in self?.handle(event) }
        }
    }

    var isPreviewing: Bool { previewClip != nil }

    func activate() {
        guard !isActive else { return }
        isActive = true
        recording.setEnabled(!isPreviewing)
    }

    func deactivate() {
        isActive = false
        recording.setEnabled(false)
        isRecording = false
        previewClip = nil
        discardClip()
    }

    func openPreview() {
        guard let clip else { return }
        dismissTask?.cancel()
        clearNotice()
        previewClip = clip
        recording.setEnabled(false)
        camera.stop()
    }

    func closePreview() {
        guard isPreviewing else { return }
        previewClip = nil
        clearNotice()
        if isActive {
            camera.start()
            recording.setEnabled(true)
        }
        scheduleDismiss()
    }

    func setThumbnailHeld(_ isHeld: Bool) {
        if isHeld { dismissTask?.cancel() } else { scheduleDismiss() }
    }

    func delete() {
        discardClip()
        closePreview()
    }

    func save() async {
        guard let clip, !isSaving else { return }
        isSaving = true
        let result = await photos.saveVideo(at: clip.url)
        isSaving = false
        switch result {
        case .saved:
            discardClip()
            closePreview()
            show(.saved)
        case .denied:
            notice = .photosDenied
        case .failed:
            notice = .saveFailed
        }
    }

    private func handle(_ event: ClipRecordingEvent) {
        switch event {
        case .started:
            clearNotice()
            isRecording = true
        case .cancelled:
            isRecording = false
        case .finished(let newClip):
            isRecording = false
            guard isActive, !isPreviewing else { return recording.discard(newClip) }
            discardClip()
            clip = newClip
            scheduleDismiss()
            Task { [weak self, recording] in
                let image = await recording.thumbnail(for: newClip)
                guard let self, clip == newClip else { return }
                thumbnail = image
            }
        }
    }

    private func discardClip() {
        dismissTask?.cancel()
        if let clip { recording.discard(clip) }
        clip = nil
        thumbnail = nil
    }

    private func scheduleDismiss() {
        dismissTask?.cancel()
        guard clip != nil, !isPreviewing else { return }
        dismissTask = Task { [weak self] in
            guard (try? await Task.sleep(for: RecordingConfig.thumbnailLifetime)) != nil else { return }
            self?.discardClip()
        }
    }

    private func show(_ value: ClipNotice) {
        notice = value
        noticeTask?.cancel()
        noticeTask = Task { [weak self] in
            guard (try? await Task.sleep(for: RecordingConfig.noticeLifetime)) != nil else { return }
            self?.notice = nil
        }
    }

    private func clearNotice() {
        noticeTask?.cancel()
        notice = nil
    }
}
