import SwiftUI

struct ClipStatusLabel: View {
    let text: String
    var showsRecordingDot = false
    var actionTitle: String?
    var action: (() -> Void)?

    private var hasAction: Bool { actionTitle != nil && action != nil }

    var body: some View {
        HStack(spacing: 8) {
            if showsRecordingDot {
                Circle()
                    .fill(.red)
                    .frame(width: RecordingConfig.recordingDotSize, height: RecordingConfig.recordingDotSize)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(minWidth: RecordingConfig.minTapTarget, minHeight: RecordingConfig.minTapTarget)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, hasAction ? 0 : 12)
        .background(Color.appInactive.opacity(0.8), in: Capsule())
        .accessibilityElement(children: hasAction ? .contain : .combine)
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            ClipStatusLabel(text: "Recording", showsRecordingDot: true)
            ClipStatusLabel(text: "Saved to Photos")
            ClipStatusLabel(text: "Video deleted", actionTitle: "Undo", action: {})
        }
    }
}
