import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenSplash") private var hasSeenSplash = false
    let mirrorViewModel: MirrorViewModel
    let makeOnboardingSignals: () -> ZoomOnboardingSignals
    let analytics: AnalyticsRecording
    let clipReviewViewModel: ClipReviewViewModel

    var body: some View {
        Group {
            if hasSeenSplash || hasCompletedOnboarding {
                NavigationStack {
                    ZStack {
                        MirrorView(viewModel: mirrorViewModel, showsControls: hasCompletedOnboarding,
                                   clipReview: clipReviewViewModel) {
                            withAnimation(.easeInOut) { hasCompletedOnboarding = false }
                        }

                        if !hasCompletedOnboarding, mirrorViewModel.cameraState != .failed, mirrorViewModel.permission != .denied {
                            OnboardingFlow(signals: makeOnboardingSignals(), analytics: analytics) {
                                withAnimation(.easeInOut) { hasCompletedOnboarding = true }
                            }
                            .transition(.opacity)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .mirrorBarStyle()
                }
            } else {
                SplashView { withAnimation(.easeInOut) { hasSeenSplash = true } }
                    .transition(.opacity)
            }
        }
        .environment(\.isLargerButtons, mirrorViewModel.isLargerButtons)
        .preferredColorScheme(Self.forcedScheme)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    private static var forcedScheme: ColorScheme? {
        if #available(iOS 26, *) { return .light }
        return nil
    }
}

#Preview {
    let container = AppContainer()
    return ContentView(mirrorViewModel: container.mirrorViewModel,
                       makeOnboardingSignals: container.makeOnboardingSignals,
                       analytics: container.analytics,
                       clipReviewViewModel: container.clipReviewViewModel)
}
