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
        RingLightPanels(level: viewModel.ringLightLevel, color: edgeColor,
                        maxSideFraction: viewModel.ringLightWidth,
                        softness: viewModel.ringLightSoftness)
            .ignoresSafeArea()
    }

    var edgeColor: Color {
        switch viewModel.filterColor {
        case .warm: LightColor.warm.color
        case .cool: LightColor.cool.color
        case .natural, nil: autoEdgeColor
        }
    }

    var autoEdgeColor: Color {
        let zoomProgress = (viewModel.zoomState.scale - 1) / (LightingTuning.autoShiftFullScale - 1)
        let progress = max(Double(min(max(zoomProgress, 0), 1)), viewModel.closeness)
        let t = LightingTuning.autoShiftStrength * min(max(progress, 0), 1)
        let c = LightingTuning.blend(Self.whiteHex, LightingTuning.softBlue, t)
        return Color(red: c.r, green: c.g, blue: c.b)
    }
}
