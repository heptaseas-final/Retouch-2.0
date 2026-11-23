//
//  OnboardingView.swift
//  Retouch
//
//  Created by Gabriella Angelina Widjaja on 06/11/26.
//

import SwiftUI

struct OnboardingView<Camera: View, RecordingThumbnail: View, RecordingPreview: View>: View {
    @State private var coordinator: OnboardingCoordinator
    private let signalSource: any OnboardingSignalSource
    private let clipState: OnboardingClipState
    private let camera: (FacePart, LightMode, Bool) -> Camera
    private let recordingThumbnail: (ControlEmphasis) -> RecordingThumbnail
    private let recordingPreview: () -> RecordingPreview

    @State private var pickerSwipe = PickerSwipe()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverOn

    private let handSize: CGFloat = 277
    private let overallVideoSize: CGFloat = 583
    private let announceDelay: Duration = .seconds(1)
    private let spotlightPadding: CGFloat = 10
    private let controlsHeight: CGFloat = 66
    @Environment(\.isLargerButtons) private var isLargerButtons
    @Environment(\.dynamicTypeSize) private var typeSize
    private let layoutSpace = "onboardingLayout"

    @State private var controlsFrame: CGRect = .zero

    init(
        signalSource: any OnboardingSignalSource,
        autoPart: FacePart = .face,
        clipState: OnboardingClipState,
        analytics: OnboardingAnalyticsRecording,
        onFinish: @escaping () -> Void,
        @ViewBuilder camera: @escaping (FacePart, LightMode, Bool) -> Camera,
        @ViewBuilder recordingThumbnail: @escaping (ControlEmphasis) -> RecordingThumbnail,
        @ViewBuilder recordingPreview: @escaping () -> RecordingPreview
    ) {
        _coordinator = State(initialValue: OnboardingCoordinator(autoPart: autoPart, analytics: analytics, onFinish: onFinish))
        self.signalSource = signalSource
        self.clipState = clipState
        self.camera = camera
        self.recordingThumbnail = recordingThumbnail
        self.recordingPreview = recordingPreview
    }

    var body: some View {
        let step = coordinator.step

        ZStack {
            camera(coordinator.selectedPart, coordinator.lightMode, step.isOverallOnly)
                .ignoresSafeArea()

            if step.focus == .picker {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack {
                    if step.showsRecording {
                        recordingThumbnail(step.focus == .recording
                                           ? .highlighted(Color.pickerGlow, guide: step.spokenInstruction) : .normal)
                    }
                    controls(for: step)
                }
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(layoutSpace)) } action: { controlsFrame = $0 }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .overlayPreferenceValue(SpotlightTargetKey.self) { target in
                GeometryReader { proxy in
                    SpotlightShape(hole: target.map { proxy[$0].insetBy(dx: -spotlightPadding, dy: -spotlightPadding) },
                                   animatesHole: !reduceMotion)
                        .fill(Color.spotlightColor.opacity(spotlightOpacity(for: step)), style: FillStyle(eoFill: true))
                }
                .allowsHitTesting(false)
            }

            if showsSwipeHand {
                swipeHand
            }

            if step == .overallIntro {
                overallVideo
            }

            if step.showsRecording {
                recordingPreview()
            }

            VStack(spacing: 0) {
                bubble(at: .top)
                    .padding(.top, 8)
                Spacer(minLength: 0)
                bubble(at: .bottom)
                    .padding(.bottom, 16)
                Color.clear
                    .frame(height: bottomReserve)
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .accessibilityElement(children: .contain)
            .accessibilitySortPriority(1)
        }
        .coordinateSpace(.named(layoutSpace))
        .toolbar { skipButton(for: step) }
        .pickerSwipe(pickerSwipe, isEnabled: step.focus == .picker)
        .animation(.easeInOut(duration: 0.2), value: pickerSwipe.isDragging)
        .animation(.snappy, value: coordinator.step)
        .animation(.snappy, value: coordinator.isBubbleVisible)
        .onChange(of: isVoiceOverOn, initial: true) { _, isOn in coordinator.isVoiceOverOn = isOn }
        .onChange(of: clipState) { old, new in coordinator.clipStateChanged(from: old, to: new) }
        .task(id: step) { await stillVideoEndIfNeeded(step) }
        .task(id: step) { await announceIfNeeded(step) }
        .onAppear {
            coordinator.attach(signalSource)
            coordinator.start()
        }
        .onDisappear {
            coordinator.detach(signalSource)
        }
    }
    private var bottomReserve: CGFloat {
        let base = max(controlsHeight, controlsFrame.height)
        guard coordinator.lightMode.isOn else { return base }
        return base + LargerButtons.controlSize(isLarger: isLargerButtons, typeSize: typeSize)
    }

    private func spotlightOpacity(for step: OnboardingStep) -> Double {
        if step.dimsBackdrop { return 0.7 }
        return step.focus == .none || step.focus == .preview ? 0 : 0.4
    }

    private func stillVideoEndIfNeeded(_ step: OnboardingStep) async {
        guard step == .overallIntro, reduceMotion,
              (try? await Task.sleep(for: .seconds(OnboardingStep.pause))) != nil else { return }
        coordinator.receive(.videoEnded)
    }

    private func announceIfNeeded(_ step: OnboardingStep) async {
        guard step.focus == .preview, isVoiceOverOn, let text = step.spokenInstruction,
              (try? await Task.sleep(for: announceDelay)) != nil else { return }
        AccessibilityNotification.Announcement(text).post()
    }

    @ToolbarContentBuilder
    private func skipButton(for step: OnboardingStep) -> some ToolbarContent {
        if step != .done {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip", action: coordinator.skip)
            }
        }
    }

    private var showsSwipeHand: Bool {
        coordinator.step == .swipeModes && !pickerSwipe.isDragging
    }

    private var swipeHand: some View {
        LoopingVideo(name: "swipe-hand", isPlaying: !reduceMotion)
            .frame(width: handSize, height: handSize)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .transition(.opacity)
    }

    private var overallVideo: some View {
        LoopingVideo(name: "overall-check", isPlaying: !reduceMotion, loops: false) {
            coordinator.receive(.videoEnded)
        }
        .frame(width: overallVideoSize, height: overallVideoSize)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .transition(.opacity)
    }

    private var lightModeBinding: Binding<LightMode> {
        Binding(
            get: { coordinator.lightMode },
            set: { coordinator.lightMode = coordinator.step.lightModeAfterTap ?? $0 }
        )
    }

    private func flashEmphasis(for step: OnboardingStep) -> ControlEmphasis {
        step.focus == .flash ? .highlighted(Color.lightGlow, guide: step.spokenInstruction) : .dimmed
    }

    private func lightColorEmphasis(for step: OnboardingStep) -> ControlEmphasis {
        step.focus == .lightColor ? .highlighted(Color.lightGlow, guide: step.spokenInstruction) : .dimmed
    }

    @ViewBuilder
    private func bubble(at position: OnboardingBubblePosition) -> some View {
        if coordinator.step.bubblePosition == position, coordinator.isBubbleVisible {
            if let text = coordinator.instruction {
                InstructionBubble(text: text, spokenText: coordinator.spokenInstruction,
                                  takesVoiceOverFocus: coordinator.step.focus == .none)
                    .id(text)
                    .transition(.opacity)
            } else if isVoiceOverOn, let spoken = coordinator.spokenInstruction {
                InstructionBubble(text: spoken, takesVoiceOverFocus: true, isVoiceOverOnly: true)
                    .id(spoken)
            }
        }
    }

    private func controls(for step: OnboardingStep) -> some View {
        CameraControls(
            part: Binding(
                get: { coordinator.selectedPart },
                set: { coordinator.selectPart($0) }
            ),
            lightMode: lightModeBinding,
            swipe: pickerSwipe,
            nextLightMode: { coordinator.nextLightMode(from: $0) },
            onLightTap: { _ in coordinator.flashTapped() },
            pickerEmphasis: step.focus == .picker ? .highlighted(Color.pickerGlow, guide: step.spokenInstruction) : .dimmed,
            flashEmphasis: flashEmphasis(for: step),
            lightColorEmphasis: lightColorEmphasis(for: step)
        )
    }
}

#Preview {
    final class PreviewSignalSource: OnboardingSignalSource {
        var onSignal: ((OnboardingTrigger) -> Void)?
    }
    final class PreviewAnalytics: OnboardingAnalyticsRecording {
        func onboardingStarted() {}
        func onboardingStepCompleted(step: String, index: Int) {}
        func onboardingSkipped(step: String) {}
        func onboardingCompleted() {}
    }
    let source = PreviewSignalSource()
    return ZStack {
        OnboardingView(signalSource: source, clipState: .empty, analytics: PreviewAnalytics(), onFinish: {}) { part, light, _ in
            (light.lightColor?.color ?? Color(white: 0.35))
                .overlay { Text(part.title).font(.largeTitle).foregroundStyle(.black.opacity(0.25)) }
        } recordingThumbnail: { _ in
            EmptyView()
        } recordingPreview: {
            EmptyView()
        }
        HStack {
            Button("Hand near eye") { source.onSignal?(.handNearEye) }
            Button("Zoomed in") { source.onSignal?(.zoomedIn) }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
    }
}
