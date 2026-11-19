import SwiftUI

@main
struct RetouchApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(mirrorViewModel: container.mirrorViewModel,
                        makeOnboardingSignals: container.makeOnboardingSignals,
                        analytics: container.analytics)
        }
    }
}
