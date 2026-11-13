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
    @State private var ignoresNextTap = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let liftDelay: Double = 0.3
    private let tapResetDelay: Duration = .milliseconds(150)
    private let inset: CGFloat = 4
    private var circleSize: CGFloat { size - inset * 2 }

    var body: some View {
        VStack(spacing: 12) {
            if let lightColor = mode.lightColor {
                indicator(for: lightColor)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.5).combined(with: .opacity))
            }
            flashButton
                .accessibilitySortPriority(1)
        }
        .accessibilityElement(children: .contain)
        .padding(inset)
        .lightGlass()
        .ringLightBorder()
        .frame(width: size, height: size, alignment: .bottom)
        .scaleEffect(isLifted && !reduceMotion ? 1.12 : 1)
        .shadow(color: .black.opacity(isLifted ? 0.25 : 0), radius: 12, y: 6)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.7), value: isLifted)
        .sensoryFeedback(.impact(weight: .medium), trigger: isLifted) { _, lifted in lifted }
    }

    private var liftGesture: some Gesture {
        LongPressGesture(minimumDuration: liftDelay)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                if !isLifted {
                    isLifted = true
                    ignoresNextTap = true
                    onLiftDrag?(.zero)
                }
                if let drag { onLiftDrag?(drag.translation) }
            }
            .onEnded { value in
                guard isLifted else { return }
                isLifted = false
                if case .second(true, let drag) = value { onLiftEnd?(drag?.translation ?? .zero) }
                Task { @MainActor in
                    try? await Task.sleep(for: tapResetDelay)
                    ignoresNextTap = false
                }
            }
    }

    private func indicator(for lightColor: LightColor) -> some View {
        Button { perform(changeColor) } label: {
            Circle()
                .fill(lightColor.color)
                .overlay(Circle().strokeBorder(Color.black.opacity(0.5), lineWidth: 1.5))
                .frame(width: circleSize, height: circleSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(liftGesture, including: onLiftDrag == nil ? .subviews : .all)
        .accessibilityLabel("Light color")
        .accessibilityInputLabels([Text("Light color"), Text("Color")])
        .accessibilityValue(lightColor.name)
        .accessibilityHint(colorEmphasis.guide ?? colorTarget?.lightColor.map { "Changes to \($0.name.lowercased())." } ?? "")
        .emphasis(colorEmphasis)
    }

    private var flashButton: some View {
        Button { perform(tap) } label: {
            Label("Light", systemImage: mode.isOn ? "bolt.fill" : "bolt.slash.fill")
                .labelStyle(.iconOnly)
                .font(.system(size: circleSize * 0.45, weight: .semibold))
                .foregroundStyle(Color.appMagenta)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: circleSize, height: circleSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(liftGesture, including: onLiftDrag == nil ? .subviews : .all)
        .sensoryFeedback(.impact(weight: .light), trigger: mode)
        .accessibilityInputLabels([Text("Light"), Text("Light button"), Text("Flash")])
        .accessibilityValue(mode.isOn ? "On" : "Off")
        .accessibilityHint(boltEmphasis.guide ?? (mode.isOn ? "Turns the light off." : "Turns the light on."))
        .accessibilityActions {
            ForEach(moveActions.indices, id: \.self) { index in
                Button(moveActions[index].label, action: moveActions[index].perform)
            }
        }
        .emphasis(boltEmphasis)
    }

    private func perform(_ action: () -> Void) {
        guard !ignoresNextTap else {
            ignoresNextTap = false
            return
        }
        action()
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

private extension View {
    @ViewBuilder
    func lightGlass() -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular.interactive(), in: Capsule())
        } else {
            background(.ultraThinMaterial, in: Capsule())
        }
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
