//
//  OnboardingFlow.swift
//  Retouch
//

import SwiftUI

struct OnboardingFlow: View {
    let onFinish: () -> Void
    @State private var signals: ZoomOnboardingSignals

    init(signals: @autoclosure () -> ZoomOnboardingSignals, onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        _signals = State(initialValue: signals())
    }

    var body: some View {
        OnboardingView(signalSource: signals, onFinish: finish) { part, light in
            OnboardingCameraControl(signals: signals, part: part, light: light)
        }
        .onAppear { signals.connect() }
        .onDisappear { signals.disconnect() }
    }

    private func finish() {
        signals.disconnect()
        signals.resetToDefaults()
        onFinish()
    }
}

struct OnboardingCameraControl: View {
    let signals: ZoomOnboardingSignals
    let part: FacePart
    let light: LightMode

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .onChange(of: part, initial: true) { _, part in signals.select(part) }
            .onChange(of: light) { _, light in signals.setLightMode(light) }
    }
}
