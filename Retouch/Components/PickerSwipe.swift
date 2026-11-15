import SwiftUI

@MainActor @Observable
final class PickerSwipe {
    struct Release: Equatable {
        let id = UUID()
        let predicted: CGFloat
    }

    private(set) var translation: CGFloat = 0
    private(set) var isDragging = false
    private(set) var release: Release?

    func update(_ dx: CGFloat) {
        translation = dx
        isDragging = true
    }

    func end(predicted dx: CGFloat) {
        guard isDragging else { return }
        release = Release(predicted: dx)
    }

    func finish() {
        isDragging = false
        translation = 0
        release = nil
    }

    func cancel() {
        guard isDragging else { return }
        withAnimation(.snappy) { finish() }
    }
}

private struct PickerSwipeGesture: ViewModifier {
    let swipe: PickerSwipe
    let isEnabled: Bool

    @State private var axis: Axis?
    @State private var isPinching = false

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(drag, including: isEnabled ? .all : .subviews)
            .simultaneousGesture(pinch, including: isEnabled ? .all : .subviews)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if axis == nil {
                    axis = abs(value.translation.width) > abs(value.translation.height) ? .horizontal : .vertical
                }
                guard axis == .horizontal, !isPinching else { return }
                swipe.update(value.translation.width)
            }
            .onEnded { value in
                defer {
                    axis = nil
                    isPinching = false
                }
                guard axis == .horizontal, !isPinching else {
                    swipe.cancel()
                    return
                }
                swipe.end(predicted: value.predictedEndTranslation.width)
            }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { _ in
                isPinching = true
                swipe.cancel()
            }
            .onEnded { _ in
                if axis == nil { isPinching = false }
            }
    }
}

extension View {
    func pickerSwipe(_ swipe: PickerSwipe, isEnabled: Bool = true) -> some View {
        modifier(PickerSwipeGesture(swipe: swipe, isEnabled: isEnabled))
    }
}
