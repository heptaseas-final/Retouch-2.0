import Foundation
import Testing
@testable import Retouch

@MainActor
struct ClipReviewViewModelTests {
    nonisolated private final class StubPhotos: PhotoLibraryServicing {
        func saveVideo(at url: URL) async -> PhotoSaveResult { .saved }
    }

    let recording = FakeClipRecordingService()
    let camera = FakeCameraService()
    let clip = RecordedClip(url: URL(filePath: "/tmp/clip.mov"), duration: 3)

    private func makeViewModelWithClip() async -> ClipReviewViewModel {
        let viewModel = ClipReviewViewModel(recording: recording, photos: StubPhotos(), camera: camera)
        viewModel.activate()
        recording.onEvent?(.finished(clip))
        for _ in 0..<5 { await Task.yield() }
        return viewModel
    }

    @Test func swipeDeleteCanBeUndone() async {
        let viewModel = await makeViewModelWithClip()
        #expect(viewModel.clip == clip)
        viewModel.deleteWithUndo()
        #expect(viewModel.clip == nil)
        #expect(viewModel.notice == .deleted)
        #expect(recording.discarded.isEmpty)
        viewModel.undoDelete()
        #expect(viewModel.clip == clip)
        #expect(viewModel.notice == nil)
        #expect(recording.discarded.isEmpty)
    }

    @Test func leavingTheAppRemovesTheDeletedVideo() async {
        let viewModel = await makeViewModelWithClip()
        viewModel.deleteWithUndo()
        viewModel.deactivate()
        #expect(recording.discarded == [clip])
        #expect(viewModel.notice == nil)
        viewModel.undoDelete()
        #expect(viewModel.clip == nil)
    }

    @Test func newRecordingRemovesTheDeletedVideo() async {
        let viewModel = await makeViewModelWithClip()
        viewModel.deleteWithUndo()
        recording.onEvent?(.started)
        for _ in 0..<5 { await Task.yield() }
        #expect(recording.discarded == [clip])
        #expect(viewModel.isRecording)
    }

    @Test func previewDeleteRemovesRightAway() async {
        let viewModel = await makeViewModelWithClip()
        viewModel.openPreview()
        viewModel.delete()
        #expect(recording.discarded == [clip])
        #expect(viewModel.notice == nil)
    }

    @Test func noticesSayVideo() {
        #expect(ClipNotice.deleted.message == "Video deleted")
        #expect(ClipNotice.saveFailed.message.contains("video"))
        #expect(ClipNotice.photosDenied.message.contains("videos"))
    }
}
