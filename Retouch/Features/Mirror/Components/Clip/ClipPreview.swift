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

    private var playing: Bool { isPlaying ?? !reduceMotion }

    var body: some View {
        VStack(spacing: 16) {
            ClipPlayer(url: clip.url, isPlaying: playing)
                .aspectRatio(RecordingConfig.clipAspectRatio, contentMode: .fit)
                .clipShape(.rect(cornerRadius: RecordingConfig.previewCornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: RecordingConfig.previewCornerRadius)
                        .strokeBorder(.white, lineWidth: RecordingConfig.thumbnailBorderWidth)
                }
                .overlay(alignment: .bottomLeading) {
                    Button(playing ? "Pause" : "Play", systemImage: playing ? "pause.fill" : "play.fill") {
                        isPlaying = !playing
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(ClipActionStyle(isProminent: false, isCircle: true))
                    .padding(12)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Clip preview")

            if let message {
                ClipStatusLabel(text: message)
            }

            HStack(spacing: 12) {
                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                    .buttonStyle(ClipActionStyle(isProminent: false))
                Button(action: onSave) {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                }
                .buttonStyle(ClipActionStyle(isProminent: true))
                .accessibilityLabel("Save to Photos")
                Button("Close", systemImage: "xmark", action: onClose)
                    .buttonStyle(ClipActionStyle(isProminent: false))
            }
            .disabled(isSaving)
        }
    }
}

struct ClipActionStyle: ButtonStyle {
    let isProminent: Bool
    var isCircle = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(isProminent ? .white : .black)
            .padding(.horizontal, isCircle ? 0 : 16)
            .frame(minWidth: RecordingConfig.minTapTarget, minHeight: RecordingConfig.minTapTarget)
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
                    message: "Couldn't save the clip. Try again.", isSaving: false,
                    onDelete: {}, onSave: {}, onClose: {})
            .padding(24)
    }
}
