//
//  MirrorGlowLayer.swift
//  Retouch
//
//  Created by Davin P on 18/11/26.
//
import SwiftUI

struct MirrorGlowLayer: View {
    let viewModel: MirrorViewModel

    private static let whiteHex: UInt32 = 0xFFFFFF

    var body: some View {
        RingLightPanels(progress: viewModel.glowProgress, isOverall: viewModel.zoomTarget == .overall,
                        opacity: viewModel.glowOpacity, color: edgeColor)
            .animation(GlowFrame.overallAnimation, value: viewModel.zoomTarget == .overall)
            .ignoresSafeArea()
    }

    private static let autoEdgeColor: Color = {
        let c = LightingTuning.blend(whiteHex, LightingTuning.softBlue, LightingTuning.autoShiftStrength)
        return Color(red: c.r, green: c.g, blue: c.b)
    }()

    var edgeColor: Color {
        switch viewModel.filterColor {
        case .warm: LightColor.warm.color
        case .cool: LightColor.cool.color
        case .natural: LightColor.white.color
        case nil: Self.autoEdgeColor
        }
    }
}
