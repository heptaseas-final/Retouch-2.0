//
//  OnboardingView.swift
//  Retouch
//
//  Created by Gabriella Angelina Widjaja on 06/11/26.
//

import SwiftUI

struct OnboardingView<Camera: View>: View {
    @State private var coordinator: OnboardingCoordinator
    private let signalSource: any OnboardingSignalSource
    private let camera: (FacePart, LightMode) -> Camera

    @State private var pickerSwipe = PickerSwipe()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverOn

    private let handSize: CGFloat = 200
    private let spotlightPadding: CGFloat = 10
    private let controlsHeight: CGFloat = 66
    private let minTapTarget: CGFloat = 44
    @Environment(\.isLargerButtons) private var isLargerButtons
    @Environment(\.dynamicTypeSize) private var typeSize
    private let layoutSpace = "onboardingLayout"

    @State private var controlsFrame: CGRect = .zero

    init(
        signalSource: any OnboardingSignalSource,
        autoPart: FacePart = .face,
        onFinish: @escaping () -> Void,
        @ViewBuilder camera: @escaping (FacePart, LightMode) -> Camera
    ) {
        _coordinator = State(initialValue: OnboardingCoordinator(autoPart: autoPart, onFinish: onFinish))
        self.signalSource = signalSource
        self.camera = camera
    }

    var body: some View {
        let step = coordinator.step

        ZStack {
            camera(coordinator.selectedPart, coordinator.lightMode)
                .ignoresSafeArea()

            if step.focus == .picker {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                controls(for: step)
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
        .pickerSwipe(pickerSwipe, isEnabled: step.focus == .picker)
        .animation(.easeInOut(duration: 0.2), value: pickerSwipe.isDragging)
        .animation(.snappy, value: coordinator.step)
        .animation(.snappy, value: coordinator.isBubbleVisible)
        .onChange(of: isVoiceOverOn, initial: true) { _, isOn in coordinator.isVoiceOverOn = isOn }
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
        return step.focus == .none ? 0 : 0.4
    }

    private func topBar(for step: OnboardingStep) -> some View {
        HStack {
            Spacer()
            if step != .done {
                Button { coordinator.skip() } label: {
                    Text("Skip")
                        .padding(.horizontal, 12)
                        .frame(minWidth: minTapTarget, minHeight: minTapTarget)
                        .background(.black.opacity(0.55), in: Capsule())
                        .background(.ultraThinMaterial, in: Capsule())
                        .contentShape(Capsule())
                }
                .font(.subheadline)
                .underline()
                .largerButtonsTypeSize(isLargerButtons)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 2)
            }
        }
        .frame(minHeight: minTapTarget)
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
        if coordinator.step.bubblePosition == position,
           coordinator.isBubbleVisible,
           let text = coordinator.instruction {
            InstructionBubble(text: text, spokenText: coordinator.spokenInstruction,
                              takesVoiceOverFocus: coordinator.step.focus == .none)
                .id(text)
                .transition(.opacity)
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
    let source = PreviewSignalSource()
    return ZStack {
        OnboardingView(signalSource: source, onFinish: {}) { part, light in
            (light.lightColor?.color ?? Color(white: 0.35))
                .overlay { Text(part.title).font(.largeTitle).foregroundStyle(.black.opacity(0.25)) }
        }
        HStack {
            Button("Hand near eye") { source.onSignal?(.handNearEye) }
            Button("Zoomed in") { source.onSignal?(.zoomedIn) }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
    }
}
