//
//  GlassStyle.swift
//  Retouch
//
//  Created by Davin P on 25/10/26.
//

import SwiftUI

enum GlassConfig {
    enum Variant { case white, transparent }
    static let variant: Variant = .white
}

struct GlassStyleModifier<S: Shape>: ViewModifier {
    let shape: S

    @Environment(\.colorSchemeContrast) private var contrast

    private var isIncreased: Bool { contrast == .increased }

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(glass, in: shape)
        } else {
            content.background {
                shape.fill(.ultraThinMaterial)
                if GlassConfig.variant == .white {
                    shape.fill(.white.opacity(isIncreased ? 0.85 : 0.25))
                }
            }
        }
    }

    @available(iOS 26, *)
    private var glass: Glass {
        switch GlassConfig.variant {
        case .white: .regular.tint(.white.opacity(isIncreased ? 0.85 : 0.5))
        case .transparent: isIncreased ? .regular.tint(.white.opacity(0.85)) : .clear
        }
    }
}

extension View {
    func glassStyle<S: Shape>(in shape: S) -> some View {
        modifier(GlassStyleModifier(shape: shape))
    }
}
