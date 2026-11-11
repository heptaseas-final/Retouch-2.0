//
//  CameraControls.swift
//  Retouch
//

import SwiftUI

struct SpotlightTargetKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

enum ControlEmphasis: Equatable {
    case normal
    case dimmed
    case highlighted(Color)
}

struct CameraControls: View {
    @Binding var part: FacePart
    @Binding var lightMode: LightMode
    let swipe: PickerSwipe
    var nextLightMode: (LightMode) -> LightMode = { $0.next }
    var onLightTap: ((LightMode) -> Void)? = nil
    var pickerEmphasis: ControlEmphasis = .normal
    var flashEmphasis: ControlEmphasis = .normal
    var lightColorEmphasis: ControlEmphasis = .normal
    var isLightDocked = true
    var lightOffset: CGSize = .zero
    var onLightLiftDrag: ((CGSize) -> Void)? = nil
    var onLightLiftEnd: ((CGSize) -> Void)? = nil
    var onLightMoveToSide: (() -> Void)? = nil
    var onLightSlotCenter: ((CGPoint) -> Void)? = nil
    var onPickerLayoutChange: ((Bool) -> Void)? = nil

    var height: CGFloat = 54
    var expandedHeight: CGFloat = 66
    var pickerWidth: CGFloat = 233

    @State private var availableWidth: CGFloat = 0
    @Environment(\.dynamicTypeSize) private var typeSize

    private let columnSpacing: CGFloat = 20
    private let minControlGap: CGFloat = 12
    private let pickerSlotPadding: CGFloat = 20

    private var lightButtonEmphasis: ControlEmphasis {
        flashEmphasis == .dimmed && lightColorEmphasis == .dimmed ? .dimmed : .normal
    }

    private var fittedPickerWidth: CGFloat {
        guard availableWidth > 0 else { return pickerWidth }
        let minSideColumn = height - 2 * (columnSpacing - minControlGap)
        return min(pickerWidth, availableWidth - 2 * (columnSpacing + minSideColumn))
    }

    private var pickerFont: UIFont { PickerMetrics.font(for: typeSize) }

    private var pickerExpandedHeight: CGFloat {
        PickerMetrics.height(height, font: pickerFont) + expandedHeight - height
    }

    private var widestPickerSlot: CGFloat {
        let widestTitle = FacePart.allCases.map { PickerMetrics.textWidth(pickerTitle($0), font: pickerFont) }.max() ?? 0
        return widestTitle + 2 * pickerSlotPadding
    }

    private var isPickerFullWidth: Bool {
        availableWidth > 0 && widestPickerSlot > fittedPickerWidth
    }

    var body: some View {
        Group {
            if isPickerFullWidth {
                picker(width: availableWidth)
            } else {
                dockedLayout
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
        .onChange(of: isPickerFullWidth, initial: true) { _, isFull in onPickerLayoutChange?(isFull) }
    }

    private var dockedLayout: some View {
        HStack(alignment: .bottom, spacing: columnSpacing) {
            ZStack {
                if isLightDocked {
                    LightModeButton(mode: $lightMode, onChange: onLightTap, nextMode: nextLightMode, size: height,
                                    onLiftDrag: onLightLiftDrag, onLiftEnd: onLightLiftEnd,
                                    moveAction: onLightMoveToSide.map { ("Move to side", $0) },
                                    boltEmphasis: lightButtonEmphasis == .dimmed ? .normal : flashEmphasis,
                                    colorEmphasis: lightButtonEmphasis == .dimmed ? .normal : lightColorEmphasis)
                        .emphasis(lightButtonEmphasis)
                        .offset(lightOffset)
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
            .padding(.bottom, (expandedHeight - height) / 2)
            .frame(maxWidth: .infinity)
            .zIndex(1)

            picker(width: fittedPickerWidth)

            Color.clear
                .frame(maxWidth: .infinity, maxHeight: pickerExpandedHeight)
        }
    }

    private func picker(width: CGFloat) -> some View {
        HorizontalPicker(items: FacePart.allCases, selection: $part, swipe: swipe, width: width,
                         padding: pickerSlotPadding, height: height, expandedHeight: expandedHeight, title: pickerTitle)
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
            self.opacity(0.5).allowsHitTesting(false)
        case .highlighted:
            self.anchorPreference(key: SpotlightTargetKey.self, value: .bounds) { $0 }
        }
    }
}
