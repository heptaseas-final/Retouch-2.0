//
//  LightModeButton.swift
//  Retouch
//
//  Created by Gabriella Angelina Widjaja on 06/11/26.
//

import SwiftUI

struct LightModeButton: View {
    @Binding var mode: LightMode
    var onChange: ((LightMode) -> Void)? = nil
    var nextMode: (LightMode) -> LightMode = { $0.next }

    var size: CGFloat = 46
    var onLiftDrag: ((CGSize) -> Void)? = nil
    var onLiftEnd: ((CGSize) -> Void)? = nil
    var moveActions: [(label: String, perform: () -> Void)] = []
    var boltEmphasis: ControlEmphasis = .normal
    var colorEmphasis: ControlEmphasis = .normal

    @State private var isLifted = false
    @State private var isPressing = false
    @State private var movedTooFar = false
    @State private var liftOrigin: CGSize = .zero
    @State private var lastTranslation: CGSize = .zero
    @State private var liftTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tapSlop: CGFloat = 10

    private let inset: CGFloat = 4
    private var circleSize: CGFloat { size - inset * 2 }

    var body: some View {
        flashButton
            .padding(inset)
            .background(alignment: .bottom) {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(Capsule().fill(Color.white.opacity(0.6)))
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.1), lineWidth: 1))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                    .frame(height: mode.lightColor == nil ? size : size * 2 + inset)
            }
            .overlay(alignment: .top) {
                if let lightColor = mode.lightColor {
                    indicator(for: lightColor)
                        .offset(y: -(circleSize + inset * 2))
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
                }
            }
        .scaleEffect(isLifted && !reduceMotion ? 1.12 : 1)
        .shadow(color: .black.opacity(isLifted ? 0.25 : 0), radius: 12, y: 6)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.7), value: isLifted)
        .sensoryFeedback(.impact(weight: .medium), trigger: isLifted) { _, lifted in lifted }
    }

    private func pressGesture(onTap: @escaping () -> Void) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                lastTranslation = value.translation
                if !isPressing {
                    isPressing = true
                    scheduleLift()
                }
                if isLifted {
                    onLiftDrag?(value.translation - liftOrigin)
                } else if hypot(value.translation.width, value.translation.height) > tapSlop {
                    movedTooFar = true
                    liftTask?.cancel()
                }
            }
            .onEnded { value in
                liftTask?.cancel()
                if isLifted {
                    isLifted = false
                    onLiftEnd?(value.translation - liftOrigin)
                } else if !movedTooFar {
                    onTap()
                }
                isPressing = false
                movedTooFar = false
            }
    }

    private func scheduleLift() {
        guard onLiftDrag != nil else { return }
        liftTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, isPressing, !movedTooFar else { return }
            liftOrigin = lastTranslation
            isLifted = true
            onLiftDrag?(.zero)
        }
    }

    private func indicator(for lightColor: LightColor) -> some View {
        Circle()
            .fill(lightColor.color)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.2), lineWidth: 1.5))
            .frame(width: circleSize, height: circleSize)
            .shadow(color: lightColor.color.opacity(0.6), radius: 10)
            .contentShape(Circle())
            .gesture(pressGesture(onTap: changeColor))
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Light color")
            .accessibilityInputLabels([Text("Light color"), Text("Color")])
            .accessibilityValue(lightColor.name)
            .accessibilityHint(colorEmphasis.guide ?? colorTarget?.lightColor.map { "Changes to \($0.name.lowercased())." } ?? "")
            .accessibilityAction { changeColor() }
            .emphasis(colorEmphasis)
    }

    private var flashFace: some View {
        Image(systemName: mode.isOn ? "bolt.fill" : "bolt.slash.fill")
            .font(.system(size: circleSize * 0.45, weight: .semibold))
            .foregroundStyle(Color.appMagenta)
            .contentTransition(.symbolEffect(.replace))
            .frame(width: circleSize, height: circleSize)
            .background(Circle().fill(buttonFill))
            .overlay(Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 1))
    }

    private var buttonFill: LinearGradient {
        LinearGradient(colors: [.white, Color(white: 0.94)], startPoint: .top, endPoint: .bottom)
    }

    private var flashButton: some View {
        flashFace
            .contentShape(Circle())
            .gesture(pressGesture(onTap: tap))
            .sensoryFeedback(.impact(weight: .light), trigger: mode)
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Light")
            .accessibilityInputLabels([Text("Light"), Text("Light button"), Text("Flash")])
            .accessibilityValue(mode.isOn ? "On" : "Off")
            .accessibilityHint(boltEmphasis.guide ?? (mode.isOn ? "Turns the light off." : "Turns the light on."))
            .accessibilityAction { tap() }
            .accessibilityActions {
                ForEach(moveActions.indices, id: \.self) { index in
                    Button(moveActions[index].label, action: moveActions[index].perform)
                }
            }
            .emphasis(boltEmphasis)
    }

    private func tap() {
        set(mode.isOn ? .off : nextMode(.off))
    }

    private var colorTarget: LightMode? {
        guard let current = mode.lightColor else { return nil }
        let suggested = nextMode(mode)
        if suggested.isOn, suggested != mode { return suggested }
        let all = LightColor.allCases
        let index = all.firstIndex(of: current) ?? 0
        return .on(all[(index + 1) % all.count])
    }

    private func changeColor() {
        if let colorTarget { set(colorTarget) }
    }

    private func set(_ newMode: LightMode) {
        guard newMode != mode else { return }
        withAnimation(.snappy) { mode = newMode }
        onChange?(newMode)
    }
}

#Preview {
    struct Demo: View {
        @State private var mode: LightMode = .off
        var body: some View {
            HStack(alignment: .bottom) {
                LightModeButton(mode: $mode) { print("Mode:", $0.label) }
                Spacer()
            }
            .padding()
        }
    }
    return Demo()
}

private func - (lhs: CGSize, rhs: CGSize) -> CGSize {
    CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}
