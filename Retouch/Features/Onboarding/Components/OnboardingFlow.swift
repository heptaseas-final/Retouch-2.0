//
//  OnboardingFlow.swift
//  Retouch
//

import SwiftUI

struct OnboardingFlow<RecordingThumbnail: View, RecordingPreview: View>: View {
    let clipState: OnboardingClipState
    let onFinish: () -> Void
    private let analytics: OnboardingAnalyticsRecording
    private let recordingThumbnail: (ControlEmphasis) -> RecordingThumbnail
    private let recordingPreview: () -> RecordingPreview
    @State private var signals: ZoomOnboardingSignals

    init(signals: @autoclosure () -> ZoomOnboardingSignals, clipState: OnboardingClipState,
         analytics: OnboardingAnalyticsRecording, onFinish: @escaping () -> Void,
         @ViewBuilder recordingThumbnail: @escaping (ControlEmphasis) -> RecordingThumbnail,
         @ViewBuilder recordingPreview: @escaping () -> RecordingPreview) {
        self.clipState = clipState
        self.analytics = analytics
        self.onFinish = onFinish
        self.recordingThumbnail = recordingThumbnail
        self.recordingPreview = recordingPreview
        _signals = State(initialValue: signals())
    }

    var body: some View {
        OnboardingView(signalSource: signals, clipState: clipState, analytics: analytics, onFinish: finish,
                       camera: { part, light, isOverallOnly in
                           OnboardingCameraControl(signals: signals, part: part, light: light, isOverallOnly: isOverallOnly)
                       },
                       recordingThumbnail: recordingThumbnail, recordingPreview: recordingPreview)
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
    let isOverallOnly: Bool

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .onChange(of: part, initial: true) { _, part in signals.select(part) }
            .onChange(of: light) { _, light in signals.setLightMode(light) }
            .onChange(of: isOverallOnly) { _, isOn in signals.setOverallOnly(isOn) }
    }
}
