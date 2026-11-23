import SwiftUI

struct ClipReviewView: View {
    @State private var viewModel: ClipReviewViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let isGuided: Bool
    private let thumbnailEmphasis: ControlEmphasis

    init(viewModel: ClipReviewViewModel, isGuided: Bool = false, thumbnailEmphasis: ControlEmphasis = .normal) {
        _viewModel = State(initialValue: viewModel)
        self.isGuided = isGuided
        self.thumbnailEmphasis = thumbnailEmphasis
    }

    @ViewBuilder
    private func noticeLabel(_ notice: ClipNotice) -> some View {
        if notice == .deleted {
            ClipStatusLabel(text: notice.message, actionTitle: "Undo", action: viewModel.undoDelete)
        } else {
            ClipStatusLabel(text: notice.message)
        }
    }

    private var slotTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity)
    }

    private var discardAction: (() -> Void)? {
        guard !isGuided else { return nil }
        return viewModel.deleteWithUndo
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if viewModel.isRecording {
                ClipStatusLabel(text: "Recording", showsRecordingDot: true)
                    .transition(slotTransition)
            } else if let clip = viewModel.clip, let thumbnail = viewModel.thumbnail, !viewModel.isPreviewing {
                ClipThumbnail(image: thumbnail, duration: clip.duration,
                              onOpen: viewModel.openPreview, onHoldChanged: viewModel.setThumbnailHeld,
                              onDiscard: discardAction)
                    .emphasis(thumbnailEmphasis)
                    .transition(slotTransition)
            } else if let notice = viewModel.notice, notice != .saved, !viewModel.isPreviewing {
                noticeLabel(notice)
                    .transition(slotTransition)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .animation(reduceMotion ? nil : .snappy, value: viewModel.isRecording)
        .animation(reduceMotion ? nil : .snappy, value: viewModel.thumbnail == nil)
        .animation(reduceMotion ? nil : .snappy, value: viewModel.notice)
        .sensoryFeedback(trigger: viewModel.isRecording) { _, isOn in isOn ? .start : .stop }
        .onAppear {
            viewModel.setKeepsThumbnail(isGuided)
            viewModel.activate()
        }
        .onDisappear {
            if !isGuided { viewModel.deactivate() }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: viewModel.activate()
            case .inactive: viewModel.pauseRecording()
            case .background: viewModel.deactivate()
            @unknown default: break
            }
        }
        .onChange(of: viewModel.isRecording) { _, isOn in
            AccessibilityNotification.Announcement(isOn ? "Recording video" : "Recording stopped").post()
        }
        .onChange(of: viewModel.notice) { _, notice in
            if notice == .deleted { AccessibilityNotification.Announcement(ClipNotice.deleted.message).post() }
        }
    }
}
