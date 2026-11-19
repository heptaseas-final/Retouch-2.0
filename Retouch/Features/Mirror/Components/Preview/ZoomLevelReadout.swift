//
//  ZoomLevelReadout.swift
//  Retouch
//
//  Created by Davin P on 17/11/26.
//


import SwiftUI

struct ZoomLevelReadout: View {
    let viewModel: MirrorViewModel

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel("Zoom level")
            .accessibilityValue(viewModel.zoomLevelText)
    }
}