import SwiftUI

enum ControlPalette {
    private static let floorOpacity = 0.12
    private static let highContrastFloor = 0.75

    static func text(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .black
    }

    static func floor(_ scheme: ColorScheme, contrast: ColorSchemeContrast) -> Color {
        let opacity = contrast == .increased ? highContrastFloor : floorOpacity
        return scheme == .dark ? .black.opacity(opacity) : .white.opacity(opacity)
    }
}
