import SwiftUI

struct ClipPreviewLayer: View {
    @State private var viewModel: ClipReviewViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(viewModel: ClipReviewViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var cardTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: RecordingConfig.previewStartScale, anchor: .bottomTrailing)
            .combined(with: .opacity)
    }

    var body: some View {
        ZStack {
            if let clip = viewModel.previewClip {
                Button(action: viewModel.closePreview) {
                    Color.black.opacity(RecordingConfig.previewDimOpacity)
                        .ignoresSafeArea()
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
                .transition(.opacity)

                ClipPreview(clip: clip, message: viewModel.notice?.message, isSaving: viewModel.isSaving,
                            onDelete: viewModel.delete,
                            onSave: { Task { await viewModel.save() } },
                            onClose: viewModel.closePreview)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .transition(cardTransition)
                    .accessibilityAddTraits(.isModal)
            }
        }
        .animation(reduceMotion ? .easeInOut : .snappy, value: viewModel.previewClip)
    }
}
