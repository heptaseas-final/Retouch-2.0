import SwiftUI

struct ClipThumbnail: View {
    let image: CGImage
    let duration: TimeInterval
    let onOpen: () -> Void
    let onHoldChanged: (Bool) -> Void
    let onDiscard: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var isHolding = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDiscarding = false

    private var seconds: Int { Int(duration.rounded()) }

    private var swipeProgress: Double {
        Double(min(max(-dragOffset.height, 0) / RecordingConfig.thumbnailSwipeDistance, 1))
    }

    var body: some View {
        Image(decorative: image, scale: 1)
            .resizable()
            .scaledToFill()
            .frame(width: RecordingConfig.thumbnailSize.width, height: RecordingConfig.thumbnailSize.height)
            .clipShape(.rect(cornerRadius: RecordingConfig.thumbnailCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: RecordingConfig.thumbnailCornerRadius)
                    .strokeBorder(.white, lineWidth: RecordingConfig.thumbnailBorderWidth)
            }
            .overlay(alignment: .bottomTrailing) {
                Text(Duration.seconds(duration), format: .time(pattern: .minuteSecond))
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: RecordingConfig.durationShadowRadius)
                    .padding(8)
            }
            .contentShape(.rect(cornerRadius: RecordingConfig.thumbnailCornerRadius))
            .offset(dragOffset)
            .opacity(isDiscarding ? 0 : 1 - swipeProgress * RecordingConfig.thumbnailSwipeFade)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isHolding) { _, state, _ in state = true }
                    .onChanged { dragOffset = $0.translation }
                    .onEnded(release)
            )
            .onChange(of: isHolding) { _, held in onHoldChanged(held) }
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Clip, \(seconds) seconds")
            .accessibilityHint(onDiscard == nil ? "Opens the clip." : "Opens the clip. Swipe up to delete.")
            .accessibilityAction { onOpen() }
            .accessibilityActions {
                if let onDiscard { Button("Delete clip", action: onDiscard) }
            }
    }

    private func release(_ value: DragGesture.Value) {
        let travel = hypot(value.translation.width, value.translation.height)
        guard travel > RecordingConfig.thumbnailTapSlop else {
            dragOffset = .zero
            return onOpen()
        }
        let upward = -min(value.translation.height, value.predictedEndTranslation.height)
        guard let onDiscard, upward > RecordingConfig.thumbnailSwipeDistance else {
            withAnimation(.snappy) { dragOffset = .zero }
            return
        }
        withAnimation(.easeOut(duration: RecordingConfig.thumbnailDiscardDuration)) {
            if !reduceMotion { dragOffset.height -= RecordingConfig.thumbnailSwipeDistance }
            isDiscarding = true
        } completion: {
            onDiscard()
        }
    }
}
