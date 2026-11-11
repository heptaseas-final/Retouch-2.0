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

            if step == .swipeModes, !pickerSwipe.isDragging {
                LoopingVideo(name: "swipe-hand", isPlaying: !reduceMotion)
                    .frame(width: handSize, height: handSize)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }

            if step.showsHandOverlay {
                OnboardingHandOverlay(eyeAnchor: signalSource.eyeAnchor)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            VStack(spacing: 0) {
                topBar(for: step)
                bubble(at: .top)
                    .padding(.top, 8)
                Spacer(minLength: 0)
                bubble(at: .bottom)
                    .padding(.bottom, 16)
                Color.clear
                    .frame(height: controlsHeight)
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
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
        .frame(height: 44)
    }

    @ViewBuilder
    private func bubble(at position: OnboardingBubblePosition) -> some View {
        if coordinator.step.bubblePosition == position,
           coordinator.isInstructionVisible,
           let text = coordinator.step.instruction {
            InstructionBubble(text: text, width: coordinator.step.focus.isLighting ? 233 : nil)
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
            lightMode: Binding(
                get: { coordinator.lightMode },
                set: { coordinator.lightMode = coordinator.step.lightModeAfterTap ?? $0 }
            ),
            swipe: pickerSwipe,
            nextLightMode: { coordinator.nextLightMode(from: $0) },
            onLightTap: { _ in coordinator.flashTapped() },
            pickerEmphasis: step.focus == .picker ? .highlighted(pickerGlow) : .dimmed,
            flashEmphasis: step.focus == .flash ? .highlighted(flashGlow) : .dimmed,
            lightColorEmphasis: step.focus == .lightColor ? .highlighted(flashGlow) : .dimmed
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
