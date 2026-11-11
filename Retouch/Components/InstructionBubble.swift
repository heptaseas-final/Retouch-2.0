//
//  InstructionBubble.swift
//  Retouch
//
//  Created by Gabriella Angelina Widjaja on 06/11/26.
//

import SwiftUI

struct InstructionBubble: View {
    let text: String
    var width: CGFloat? = nil
    var isFullWidth = false

    private let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)

    var body: some View {
        ViewThatFits(in: .vertical) {
            label
            label.dynamicTypeSize(...DynamicTypeSize.accessibility4)
            label.dynamicTypeSize(...DynamicTypeSize.accessibility3)
            ScrollView { label.frame(maxWidth: .infinity) }
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                .scrollBounceBehavior(.basedOnSize)
        }
        .frame(width: isFullWidth ? nil : width)
        .frame(maxWidth: isFullWidth ? .infinity : (width ?? 300))
        .background {
            shape
                .fill(.ultraThinMaterial)
                .overlay(shape.fill(Color.black.opacity(0.35)))
                .overlay(shape.strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
        }
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private var label: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .accessibilityAddTraits(.isStaticText)
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
