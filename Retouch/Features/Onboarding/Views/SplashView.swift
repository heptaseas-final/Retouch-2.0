//
//  SplashView.swift
//  Retouch
//
//  Created by Gabriella Angelina Widjaja on 15/11/26.
//

import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFinished = false

    private let stillDuration: Duration = .seconds(1.5)

    var body: some View {
        Button(action: finish) {
            SplashVideo(name: "splash-screen", isStill: reduceMotion, onEnd: finish)
                .ignoresSafeArea()
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .accessibilityLabel("Retouch")
        .accessibilityHint("Skips the intro.")
        .task {
            guard reduceMotion, (try? await Task.sleep(for: stillDuration)) != nil else { return }
            finish()
        }
    }

    private func finish() {
        guard !isFinished else { return }
        isFinished = true
        onFinish()
    }
}
