import SwiftUI

extension EnvironmentValues {
    @Entry var isRingLightVisible = false
}

enum RingLightBorder {
    static let visibleLevel = 0.05
    static let lineWidth: CGFloat = 1.5
}

private struct RingLightBorderModifier: ViewModifier {
    @Environment(\.isRingLightVisible) private var isRingLightVisible
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                Capsule()
                    .strokeBorder(.black, lineWidth: RingLightBorder.lineWidth)
                    .opacity(isRingLightVisible ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isRingLightVisible)
    }
}

extension View {
    func ringLightBorder() -> some View {
        modifier(RingLightBorderModifier())
    }
}
