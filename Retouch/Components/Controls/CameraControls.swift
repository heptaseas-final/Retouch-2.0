//
//  CameraControls.swift
//  Retouch
//

import SwiftUI

struct SpotlightTargetKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>?
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

enum ControlEmphasis: Equatable {
    case normal
    case dimmed
    case highlighted(Color, guide: String? = nil)

    var guide: String? {
        if case let .highlighted(_, guide) = self { return guide }
        return nil
    }
}

struct CameraControls: View {
    @Binding var part: FacePart
    @Binding var lightMode: LightMode
    let swipe: PickerSwipe
    var nextLightMode: (LightMode) -> LightMode = { $0.next }
    var onLightTap: ((LightMode) -> Void)?
    var pickerEmphasis: ControlEmphasis = .normal
    var flashEmphasis: ControlEmphasis = .normal
    var lightColorEmphasis: ControlEmphasis = .normal
    var isLightDocked = true
    var lightOffset: CGSize = .zero
    var onLightLiftDrag: ((CGSize) -> Void)?
    var onLightLiftEnd: ((CGSize) -> Void)?
    var lightMoveActions: [(label: String, perform: () -> Void)] = []
    var onLightSlotCenter: ((CGPoint) -> Void)?
    var onPickerLayoutChange: ((Bool) -> Void)?
    var isOverallOn: Binding<Bool>?
    var isOverallEnabled = true
    var expandsPicker = false

    var expandedHeight: CGFloat = 66
    var pickerWidth: CGFloat = 233

    @State private var availableWidth: CGFloat = 0
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.isLargerButtons) private var isLargerButtons
    @Environment(\.legibilityWeight) private var legibilityWeight

    private var height: CGFloat { LargerButtons.controlSize(isLarger: isLargerButtons, typeSize: typeSize) }

    private let columnSpacing: CGFloat = 20
    private let minControlGap: CGFloat = 12
    private let regularSlotPadding: CGFloat = 20
    private let compactSlotPadding: CGFloat = 12

    private var effectiveTypeSize: DynamicTypeSize {
        LargerButtons.typeSize(typeSize, isLarger: isLargerButtons)
    }

    private var pickerSlotPadding: CGFloat {
        effectiveTypeSize > .large ? compactSlotPadding : regularSlotPadding
    }

    private var lightButtonEmphasis: ControlEmphasis {
        flashEmphasis == .dimmed && lightColorEmphasis == .dimmed ? .dimmed : .normal
    }

    private var fittedPickerWidth: CGFloat {
        guard availableWidth > 0 else { return pickerWidth }
        let minSideColumn = height - 2 * (columnSpacing - minControlGap)
        return min(pickerWidth, availableWidth - 2 * (columnSpacing + minSideColumn))
    }

    private var isPickerMoving: Bool { expandsPicker && (swipe.isDragging || swipe.isHeldByPicker) }

    private var slideDistance: CGFloat { height + columnSpacing * 2 }

    private var pickerFont: UIFont { PickerMetrics.font(for: effectiveTypeSize, isBold: legibilityWeight == .bold) }

    private var pickerExpandedHeight: CGFloat {
        PickerMetrics.height(height, font: pickerFont) + expandedHeight - height
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: columnSpacing) {
            ZStack {
                if isLightDocked {
                    LightModeButton(mode: $lightMode, onChange: onLightTap, nextMode: nextLightMode, size: height,
                                    onLiftDrag: onLightLiftDrag, onLiftEnd: onLightLiftEnd,
                                    moveActions: lightMoveActions,
                                    boltEmphasis: lightButtonEmphasis == .dimmed ? .normal : flashEmphasis,
                                    colorEmphasis: lightButtonEmphasis == .dimmed ? .normal : lightColorEmphasis)
                        .emphasis(lightButtonEmphasis)
                        .offset(lightOffset)
                        .offset(x: isPickerMoving ? -slideDistance : 0)
                        .opacity(isPickerMoving ? 0 : 1)
                        .transition(.identity)
                } else {
                    Color.clear
                        .frame(width: height, height: height)
                }
            }
            .onGeometryChange(for: CGPoint.self) { proxy in
                let frame = proxy.frame(in: .global)
                return CGPoint(x: frame.midX, y: frame.maxY - height / 2)
            } action: { center in
                onLightSlotCenter?(center)
            }
            .padding(.bottom, (pickerExpandedHeight - height) / 2)
            .frame(maxWidth: .infinity)
            .zIndex(1)

            picker(width: fittedPickerWidth)

            ZStack {
                if let isOverallOn {
                    OverallViewButton(isOn: isOverallOn, size: height)
                        .disabled(!isOverallEnabled)
                        .opacity(isOverallEnabled ? 1 : 0.5)
                        .offset(x: isPickerMoving ? slideDistance : 0)
                        .opacity(isPickerMoving ? 0 : 1)
                } else {
                    Color.clear
                        .frame(width: height, height: height)
                }
            }
            .padding(.bottom, (pickerExpandedHeight - height) / 2)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .animation(.snappy, value: isPickerMoving)
        .largerButtonsTypeSize(isLargerButtons)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
    }

    private func picker(width: CGFloat) -> some View {
        HorizontalPicker(items: FacePart.allCases, selection: $part, swipe: swipe, width: width,
                         padding: pickerSlotPadding, height: height, expandedHeight: expandedHeight,
                         expandedWidth: expandsPicker && availableWidth > 0 ? availableWidth : nil,
                         title: pickerTitle)
            .accessibilityHint(pickerEmphasis.guide ?? "")
            .emphasis(pickerEmphasis)
            .frame(width: width, height: pickerExpandedHeight)
    }

    private func pickerTitle(_ part: FacePart) -> String {
        part.title.uppercased()
    }
}

extension View {
    @ViewBuilder
    func emphasis(_ emphasis: ControlEmphasis) -> some View {
        switch emphasis {
        case .normal:
            self
        case .dimmed:
            self.opacity(0.5).allowsHitTesting(false).disabled(true).accessibilityHidden(true)
        case .highlighted(_, let guide):
            self.anchorPreference(key: SpotlightTargetKey.self, value: .bounds) { $0 }
                .modifier(GuidedFocus(guide: guide))
        }
    }
}
