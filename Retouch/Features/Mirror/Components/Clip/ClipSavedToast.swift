import SwiftUI

struct ClipSavedToast: View {
    let viewModel: ClipReviewViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if viewModel.notice == .saved {
                ClipStatusLabel(text: ClipNotice.saved.message)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? .easeInOut : .snappy, value: viewModel.notice)
        .onChange(of: viewModel.notice) { _, notice in
            if notice == .saved { AccessibilityNotification.Announcement(ClipNotice.saved.message).post() }
        }
    }
}
