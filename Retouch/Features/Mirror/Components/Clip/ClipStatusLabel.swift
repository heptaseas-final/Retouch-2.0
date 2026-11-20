import SwiftUI

struct ClipStatusLabel: View {
    let text: String
    var showsRecordingDot = false

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
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.appInactive.opacity(0.8), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            ClipStatusLabel(text: "Recording", showsRecordingDot: true)
            ClipStatusLabel(text: "Saved to Photos")
        }
    }
}
