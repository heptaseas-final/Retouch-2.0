//
//  GlowLevelSync.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 20/11/26.
//


import SwiftUI

struct GlowLevelSync: ViewModifier {
    let viewModel: MirrorViewModel

    func body(content: Content) -> some View {
        content.onChange(of: viewModel.ringLightLevel, initial: true) { _, level in
            let ramp = GlowFrame.rampDuration(from: viewModel.shownGlowLevel, to: level)
            withAnimation(.smooth(duration: ramp)) {
                viewModel.glowLevelDidChange(level)
            }
        }
    }
}

extension View {
    func syncsGlowLevel(with viewModel: MirrorViewModel) -> some View {
        modifier(GlowLevelSync(viewModel: viewModel))
    }
}