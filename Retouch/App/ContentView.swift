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
        ZStack {
            MirrorView(viewModel: mirrorViewModel, showsControls: hasCompletedOnboarding) {
                withAnimation(.easeInOut) { hasCompletedOnboarding = false }
            }

            if !hasCompletedOnboarding {
                OnboardingFlow(signals: makeOnboardingSignals()) {
                    withAnimation(.easeInOut) { hasCompletedOnboarding = true }
                }
                .transition(.opacity)
            }
        }
        .environment(\.isLargerButtons, mirrorViewModel.isLargerButtons)
        .environment(\.colorScheme, .light)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
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
