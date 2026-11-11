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

    var height: CGFloat = 54
    var expandedHeight: CGFloat = 66
    var pickerWidth: CGFloat = 233

    @State private var availableWidth: CGFloat = 0

    private let columnSpacing: CGFloat = 20
    private let minControlGap: CGFloat = 12

    private var lightButtonEmphasis: ControlEmphasis {
        flashEmphasis == .dimmed && lightColorEmphasis == .dimmed ? .dimmed : .normal
    }

    private var fittedPickerWidth: CGFloat {
        guard availableWidth > 0 else { return pickerWidth }
        let minSideColumn = height - 2 * (columnSpacing - minControlGap)
        return min(pickerWidth, availableWidth - 2 * (columnSpacing + minSideColumn))
    }

    var body: some View {
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

            HorizontalPicker(items: FacePart.allCases, selection: $part, swipe: swipe, width: fittedPickerWidth,
                             height: height, expandedHeight: expandedHeight) { $0.title.uppercased() }
                .emphasis(pickerEmphasis)
                .frame(width: fittedPickerWidth, height: expandedHeight)

            Color.clear
                .frame(maxWidth: .infinity, maxHeight: expandedHeight)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
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
