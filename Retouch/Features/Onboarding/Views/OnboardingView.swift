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

    private let pickerGlow = Color(red: 0.85, green: 0.30, blue: 0.40)
    private let flashGlow = Color(red: 0.76, green: 0.60, blue: 0.45)

    @State private var pickerSwipe = PickerSwipe()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let handSize: CGFloat = 200
    private let spotlightColor = Color(hex: 0x1D1D1D)
    private let spotlightPadding: CGFloat = 10
    private let controlsHeight: CGFloat = 66
    private let minTapTarget: CGFloat = 44
    private let lightButtonSize: CGFloat = 54
    private let bubbleGap: CGFloat = 16
    private let layoutSpace = "onboardingLayout"

    @State private var isPickerFullWidth = false
    @State private var lightFrame: CGRect = .zero
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
                if showsSideLight(for: step) {
                    sideLight(for: step)
                    Spacer(minLength: 0)
                }
                controls(for: step)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(layoutSpace)) } action: { controlsFrame = $0 }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .overlayPreferenceValue(SpotlightTargetKey.self) { target in
                GeometryReader { proxy in
                    SpotlightShape(hole: target.map { proxy[$0].insetBy(dx: -spotlightPadding, dy: -spotlightPadding) })
                        .fill(spotlightColor.opacity(spotlightOpacity(for: step)), style: FillStyle(eoFill: true))
                }
                .allowsHitTesting(false)
            }

            if showsSwipeHand, !isPickerFullWidth {
                swipeHand
            }

            if step.showsHandOverlay {
                OnboardingHandOverlay(eyeAnchor: signalSource.eyeAnchor)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            if showsSideLight(for: step), lightFrame != .zero, controlsFrame != .zero {
                fullWidthBubbles(for: step)
            } else {
                VStack(spacing: 0) {
                    topBar(for: step)
                    bubble(at: .top)
                        .padding(.top, 8)
                    Spacer(minLength: 0)
                    bottomBubble
                        .padding(.bottom, 16)
                    Color.clear
                        .frame(height: max(controlsHeight, controlsFrame.height))
                        .allowsHitTesting(false)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .coordinateSpace(.named(layoutSpace))
        .pickerSwipe(pickerSwipe, isEnabled: step.focus == .picker)
        .animation(.easeInOut(duration: 0.2), value: pickerSwipe.isDragging)
        .animation(.snappy, value: coordinator.step)
        .animation(.snappy, value: coordinator.isInstructionVisible)
        .onAppear {
            coordinator.attach(signalSource)
            coordinator.start()
        }
        .onDisappear {
            coordinator.detach(signalSource)
        }
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
                        .frame(minWidth: minTapTarget, minHeight: minTapTarget)
                        .contentShape(Rectangle())
                }
                .font(.subheadline)
                .underline()
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

    private func showsSideLight(for step: OnboardingStep) -> Bool {
        isPickerFullWidth && step.focus.isLighting
    }

    @ViewBuilder
    private var bottomBubble: some View {
        if isPickerFullWidth {
            ViewThatFits(in: .vertical) {
                VStack(spacing: bubbleGap) {
                    if showsSwipeHand { swipeHand }
                    bubble(at: .bottom)
                }
                bubble(at: .bottom)
            }
        } else {
            bubble(at: .bottom)
        }
    }

    private func fullWidthBubbles(for step: OnboardingStep) -> some View {
        let bottomStart = lightFrame.maxY + bubbleGap
        let bottomRegion = max(controlsFrame.minY - bubbleGap - bottomStart, 0)
        return ZStack(alignment: .top) {
            topBar(for: step)
            bubble(at: .bottom)
                .frame(height: bottomRegion, alignment: .bottom)
                .padding(.top, bottomStart)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 16)
    }

    private func sideLight(for step: OnboardingStep) -> some View {
        let flash = flashEmphasis(for: step)
        let color = lightColorEmphasis(for: step)
        let buttonEmphasis: ControlEmphasis = flash == .dimmed && color == .dimmed ? .dimmed : .normal
        return HStack {
            LightModeButton(mode: lightModeBinding, onChange: { _ in coordinator.flashTapped() },
                            nextMode: { coordinator.nextLightMode(from: $0) }, size: lightButtonSize,
                            boltEmphasis: buttonEmphasis == .dimmed ? .normal : flash,
                            colorEmphasis: buttonEmphasis == .dimmed ? .normal : color)
                .emphasis(buttonEmphasis)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(layoutSpace)) } action: { lightFrame = $0 }
            Spacer(minLength: 0)
        }
    }

    private var lightModeBinding: Binding<LightMode> {
        Binding(
            get: { coordinator.lightMode },
            set: { coordinator.lightMode = coordinator.step.lightModeAfterTap ?? $0 }
        )
    }

    private func flashEmphasis(for step: OnboardingStep) -> ControlEmphasis {
        step.focus == .flash ? .highlighted(flashGlow) : .dimmed
    }

    private func lightColorEmphasis(for step: OnboardingStep) -> ControlEmphasis {
        step.focus == .lightColor ? .highlighted(flashGlow) : .dimmed
    }

    @ViewBuilder
    private func bubble(at position: OnboardingBubblePosition) -> some View {
        if coordinator.step.bubblePosition == position,
           coordinator.isInstructionVisible,
           let text = coordinator.step.instruction {
            InstructionBubble(text: text, width: coordinator.step.focus.isLighting ? 233 : nil,
                              isFullWidth: isPickerFullWidth)
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
            pickerEmphasis: step.focus == .picker ? .highlighted(pickerGlow) : .dimmed,
            flashEmphasis: flashEmphasis(for: step),
            lightColorEmphasis: lightColorEmphasis(for: step),
            onPickerLayoutChange: { isPickerFullWidth = $0 }
        )
    }
}

#Preview {
    final class PreviewSignalSource: OnboardingSignalSource {
        var onSignal: ((OnboardingTrigger) -> Void)?
        var eyeAnchor: CGPoint? = CGPoint(x: 0.62, y: 0.38)
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

private struct SpotlightShape: Shape {
    var hole: CGRect?

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            let r = hole ?? .zero
            return AnimatablePair(AnimatablePair(r.midX, r.midY), AnimatablePair(r.width, r.height))
        }
        set {
            guard hole != nil else { return }
            hole = CGRect(x: newValue.first.first - newValue.second.first / 2,
                          y: newValue.first.second - newValue.second.second / 2,
                          width: newValue.second.first, height: newValue.second.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path(rect.insetBy(dx: -1000, dy: -1000))
        if let hole {
            path.addRoundedRect(in: hole, cornerSize: CGSize(width: min(hole.width, hole.height) / 2,
                                                             height: min(hole.width, hole.height) / 2))
        }
        return path
    }
}
