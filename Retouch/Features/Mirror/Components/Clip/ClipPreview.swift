import SwiftUI

struct ClipPreview: View {
    let clip: RecordedClip
    let message: String?
    let isSaving: Bool
    let onDelete: () -> Void
    let onSave: () -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPlaying: Bool?
    @State private var isConfirmingDelete = false
    @AccessibilityFocusState private var isCloseFocused: Bool

    private var playing: Bool { isPlaying ?? !reduceMotion }

    var body: some View {
        VStack(spacing: 16) {
            ClipPlayer(url: clip.url, isPlaying: playing)
                .aspectRatio(RecordingConfig.clipAspectRatio, contentMode: .fit)
                .overlay(alignment: .bottomTrailing) {
                    ClipFileTab()
                        .padding(.trailing, RecordingConfig.fileTabInset)
                }
                .clipShape(.rect(cornerRadius: RecordingConfig.previewCornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: RecordingConfig.previewCornerRadius)
                        .strokeBorder(.white, lineWidth: RecordingConfig.previewBorderWidth)
                }
                .overlay(alignment: .bottomLeading) {
                    Button(playing ? "Pause" : "Play", systemImage: playing ? "pause.fill" : "play.fill") {
                        isPlaying = !playing
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(ClipActionStyle(isProminent: false, isCircle: true))
                    .padding(12)
                }
                .overlay(alignment: .topTrailing) {
                    Button("Close", systemImage: "xmark", action: onClose)
                        .labelStyle(.iconOnly)
                        .buttonStyle(ClipActionStyle(isProminent: false, isCircle: true))
                        .offset(RecordingConfig.closeButtonOffset)
                        .accessibilityFocused($isCloseFocused)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Video preview")

            if let message {
                ClipStatusLabel(text: message)
            } else {
                Text("Save to keep this video.")
                    .font(.footnote)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 12) {
                Button("Delete", role: .destructive) { isConfirmingDelete = true }
                    .buttonStyle(ClipActionStyle(isProminent: false, fillsWidth: true))
                Button(action: onSave) {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save")
                    }
                }
                .buttonStyle(ClipActionStyle(isProminent: true, fillsWidth: true))
                .accessibilityLabel("Save to Photos")
                .accessibilityValue(isSaving ? "Saving" : "")
            }
            .disabled(isSaving)
        }
        .accessibilityAction(.escape, onClose)
        .alert("Delete this video?", isPresented: $isConfirmingDelete) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It hasn't been saved to Photos and can't be recovered.")
        }
        .onChange(of: message) { _, text in
            if let text { AccessibilityNotification.Announcement(text).post() }
        }
        .task { await focusClose() }
    }

    private func focusClose() async {
        guard (try? await Task.sleep(for: RecordingConfig.voiceOverFocusDelay)) != nil else { return }
        isCloseFocused = true
    }
}

struct ClipActionStyle: ButtonStyle {
    let isProminent: Bool
    var isCircle = false
    var fillsWidth = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(isProminent ? Color.white : (isCircle ? Color.appMagenta : Color.black))
            .padding(.horizontal, isCircle ? 0 : 16)
            .frame(minWidth: RecordingConfig.minTapTarget, maxWidth: fillsWidth ? .infinity : nil,
                   minHeight: RecordingConfig.minTapTarget)
            .background {
                if isProminent {
                    Capsule().fill(Color.appMagenta)
                } else {
                    Capsule().fill(.clear).glassStyle(in: Capsule())
                }
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.5)
            .contentShape(Capsule())
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.6).ignoresSafeArea()
        ClipPreview(clip: RecordedClip(url: URL(filePath: "/tmp/sample.mov"), duration: 3),
                    message: nil, isSaving: false,
                    onDelete: {}, onSave: {}, onClose: {})
            .padding(24)
    }
}
