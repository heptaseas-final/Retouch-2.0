//
//  ClipFileTab.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 20/11/26.
//


import SwiftUI

struct ClipFileTab: View {
    var body: some View {
        UnevenRoundedRectangle(topLeadingRadius: RecordingConfig.fileTabSize.height / 2,
                               topTrailingRadius: RecordingConfig.fileTabSize.height / 2)
            .fill(.white.opacity(0.85))
            .frame(width: RecordingConfig.fileTabSize.width, height: RecordingConfig.fileTabSize.height)
            .accessibilityHidden(true)
    }
}