//
//  InstructionBubble.swift
//  Retouch
//
//  Created by Gabriella Angelina Widjaja on 06/11/26.
//

import SwiftUI

struct InstructionBubble: View {
    let text: String
    var isFullWidth = false
    var spokenText: String? = nil
    var takesVoiceOverFocus = false

    @AccessibilityFocusState private var isFocused: Bool
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverOn

    private let width: CGFloat = 309
    private let focusDelay: Duration = .milliseconds(300)

    var body: some View {
        ViewThatFits(in: .vertical) {
            label
            ScrollView { label }
                .scrollBounceBehavior(.basedOnSize)
        }
        .frame(width: width)
        .frame(maxHeight: lineHeight * maxLines + verticalPadding * 2)
        .background(Color.appInactive.opacity(0.8), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenText ?? text)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityFocused($isFocused)
        .task(id: text) { await focusIfNeeded() }
    }

    private func focusIfNeeded() async {
        guard takesVoiceOverFocus, isVoiceOverOn, (try? await Task.sleep(for: focusDelay)) != nil else { return }
        isFocused = true
    }

    private var label: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
    }
}

#Preview {
    ZStack {
        Color.gray
        VStack(spacing: 16) {
            InstructionBubble(text: "Place your hand or makeup product near the area you want to retouch.")
            InstructionBubble(text: "Tap to see warm light.")
        }
    }
}
