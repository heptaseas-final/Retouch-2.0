//
//  ContentView.swift
//  Retouch
//
//  Created by Davin P on 21/10/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    let mirrorViewModel: MirrorViewModel
    let makeOnboardingSignals: () -> ZoomOnboardingSignals

    var body: some View {
        NavigationStack {
            ZStack {
                MirrorView(viewModel: mirrorViewModel, showsControls: hasCompletedOnboarding) {
                    withAnimation(.easeInOut) { hasCompletedOnboarding = false }
                }

                if !hasCompletedOnboarding, mirrorViewModel.cameraState != .failed, mirrorViewModel.permission != .denied {
                    OnboardingFlow(signals: makeOnboardingSignals()) {
                        withAnimation(.easeInOut) { hasCompletedOnboarding = true }
                    }
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackgroundVisibility(barBackground, for: .navigationBar)
        }
        .environment(\.isLargerButtons, mirrorViewModel.isLargerButtons)
        .environment(\.isRingLightVisible, mirrorViewModel.ringLightLevel > RingLightBorder.visibleLevel)
        .environment(\.colorScheme, .light)

    }

    private var barBackground: Visibility {
        if #available(iOS 26, *) { return .hidden }
        return .visible
    }
}

#Preview {
    let container = AppContainer()
    return ContentView(mirrorViewModel: container.mirrorViewModel,
                       makeOnboardingSignals: container.makeOnboardingSignals)
}
