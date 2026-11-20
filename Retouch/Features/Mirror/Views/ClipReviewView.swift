import SwiftUI

struct ClipReviewView: View {
    @State private var viewModel: ClipReviewViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: ClipReviewViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var slotTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if viewModel.isRecording {
                ClipStatusLabel(text: "Recording", showsRecordingDot: true)
                    .transition(slotTransition)
            } else if let clip = viewModel.clip, let thumbnail = viewModel.thumbnail, !viewModel.isPreviewing {
                ClipThumbnail(image: thumbnail, duration: clip.duration,
                              onOpen: viewModel.openPreview, onHoldChanged: viewModel.setThumbnailHeld,
                              onDiscard: viewModel.delete)
                    .transition(slotTransition)
            } else if let notice = viewModel.notice, notice != .saved, !viewModel.isPreviewing {
                ClipStatusLabel(text: notice.message)
                    .transition(slotTransition)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .animation(reduceMotion ? nil : .snappy, value: viewModel.isRecording)
        .animation(reduceMotion ? nil : .snappy, value: viewModel.thumbnail == nil)
        .animation(reduceMotion ? nil : .snappy, value: viewModel.notice)
        .sensoryFeedback(trigger: viewModel.isRecording) { _, isOn in isOn ? .start : .stop }
        .onAppear { viewModel.activate() }
        .onDisappear { viewModel.deactivate() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: viewModel.activate()
            case .inactive: viewModel.pauseRecording()
            case .background: viewModel.deactivate()
            @unknown default: break
            }
        }
        .onChange(of: viewModel.isRecording) { _, isOn in
            AccessibilityNotification.Announcement(isOn ? "Recording clip" : "Recording stopped").post()
        }
    }
}
