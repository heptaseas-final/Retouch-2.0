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
        ContentUnavailableView {
            Label("Retouch needs your camera", systemImage: "camera.fill")
        } description: {
            Text("Your camera works as the mirror. Turn on camera access in Settings.")
        } actions: {
            Button("Open Settings", action: onOpenSettings)
                .glassButtonStyle(prominent: true)
                .controlSize(.large)
                .tint(.appMagenta)
        }
        .environment(\.colorScheme, .dark)
    }
}
