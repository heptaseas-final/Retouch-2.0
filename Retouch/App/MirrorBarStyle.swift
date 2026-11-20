import SwiftUI

private struct MirrorBarStyle: ViewModifier {
    let isOverall: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .toolbarBackground(Color.clear, for: .navigationBar)
                .toolbarBackgroundVisibility(.visible, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
        } else {
            content
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        }
    }
}

extension View {
    func mirrorBarStyle(isOverall: Bool) -> some View {
        modifier(MirrorBarStyle(isOverall: isOverall))
    }
}
