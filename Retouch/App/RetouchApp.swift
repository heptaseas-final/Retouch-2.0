//
//  RetouchApp.swift
//  Retouch
//
//  Created by Davin P on 21/10/26.
//

import SwiftUI

@main
struct RetouchApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(mirrorViewModel: container.mirrorViewModel,
                        makeOnboardingSignals: container.makeOnboardingSignals)
        }
    }
}
