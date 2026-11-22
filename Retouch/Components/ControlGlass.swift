import SwiftUI

private struct ControlGlassModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content.background {
            ZStack {
                Capsule().fill(.ultraThinMaterial)
                Capsule().fill(ControlPalette.floor(colorScheme, contrast: contrast))
                ControlGlassRim()
            }
        }
    }
}

private struct ControlGlassRim: View {
    var body: some View {
        if #available(iOS 26, *) {
            Color.clear
                .glassEffect(.clear, in: Capsule())
                .allowsHitTesting(false)
        }
    }
}

extension View {
    func controlGlass() -> some View {
        modifier(ControlGlassModifier())
    }

    @ViewBuilder
    func lightOnGlassSystems() -> some View {
        if #available(iOS 26, *) {
            environment(\.colorScheme, .light)
        } else {
            self
        }
    }
}
