//
//  CameraPermissionDeniedView.swift
//  Retouch
//
//  Created by Davin P on 25/10/26.
//

import SwiftUI

struct CameraPermissionDeniedView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Retouch needs your camera")
                    .font(.headline)
                Text("Your camera works as the mirror. Turn on camera access in Settings.")
                    .font(.subheadline)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            Button("Open Settings", action: onOpenSettings)
                .buttonStyle(.borderedProminent)
                .tint(.appMagenta)
        }
    }
}
