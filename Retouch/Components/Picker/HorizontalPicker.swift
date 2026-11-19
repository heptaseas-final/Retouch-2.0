//
//  HorizontalPicker.swift
//  Retouch
//
//  Created by Gabriella Angelina Widjaja on 06/11/26.
//

import SwiftUI

struct HorizontalPicker<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let swipe: PickerSwipe
    var width: CGFloat = 233
    var padding: CGFloat = 20
    var height: CGFloat = 54
    var expandedHeight: CGFloat = 66
    var expandedWidth: CGFloat?
    let title: (Item) -> String

    @State private var base = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDraggingPicker = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.legibilityWeight) private var legibilityWeight
    @Environment(\.colorScheme) private var colorScheme

    private let maxStepsPerSwipe = 1
    private let selectionInset: CGFloat = 4
    private let pickerDragMinimum: CGFloat = 4
    private let visibleSpread = 5
    private let lensMagnify: CGFloat = 1.08
    private let rimWidth: CGFloat = 1.2

    private var rimGradient: LinearGradient {
        LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0.1), .white.opacity(0.4)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        let font = PickerMetrics.font(for: typeSize, isBold: legibilityWeight == .bold)
        let restingHeight = PickerMetrics.height(height, font: font)
        let liftedHeight = restingHeight + expandedHeight - height
        let track = PickerTrack(slots: items.map { PickerMetrics.textWidth(title($0), font: font) + 2 * padding })
        let x = position(on: track)
        let current = track.nearest(to: x, around: base)
        let isDragging = swipe.isDragging || isDraggingPicker
        let capsuleWidth = isDragging ? track.slotWidth(at: x, around: base) : track.slot(base)
        let currentHeight = isDragging ? liftedHeight : restingHeight
        let lensWidth = capsuleWidth - selectionInset * 2
        let lensHeight = currentHeight - selectionInset * 2

        let openWidth = max(expandedWidth ?? width, width)
        let shapeWidth = isDragging ? openWidth : width

        ZStack {
            Color.clear
                .frame(width: shapeWidth, height: currentHeight)
                .controlGlass()

            Capsule()
                .fill(Color.appMagenta)
                .overlay {
                    Capsule().strokeBorder(rimGradient, lineWidth: rimWidth)
                }
                .frame(width: lensWidth, height: lensHeight)

            PickerLens(width: lensWidth, height: lensHeight)

            labels(track: track, x: x, height: currentHeight, span: openWidth, font: font,
                   color: ControlPalette.text(colorScheme), tappable: true)
                .mask {
                    Rectangle()
                        .overlay {
                            Capsule()
                                .frame(width: lensWidth, height: lensHeight)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                }

            labels(track: track, x: x, height: currentHeight, span: openWidth, font: font,
                   color: .white, tappable: false)
                .scaleEffect(lensMagnify)
                .mask {
                    Capsule().frame(width: lensWidth, height: lensHeight)
                }
                .allowsHitTesting(false)
        }
        .frame(width: width, height: currentHeight)
        .mask {
            Capsule()
                .frame(width: shapeWidth, height: currentHeight)
                .frame(width: width, height: currentHeight)
        }
        .contentShape(Capsule())
        .highPriorityGesture(pickerDrag(track: track))
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
        .sensoryFeedback(.selection, trigger: current)
        .accessibilityShowsLargeContentViewer {
            Text(title(selection).capitalized)
        }
        .accessibilityElement()
        .accessibilityLabel("Zoom target")
        .accessibilityValue(title(selection).capitalized)
        .accessibilityInputLabels([Text("Zoom target"), Text("Zoom"), Text(title(selection).capitalized)])
        .accessibilityActions {
            ForEach(items, id: \.self) { item in
                Button("Select \(title(item).capitalized)") { select(item: item) }
            }
        }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: select(base + 1)
            case .decrement: select(base - 1)
            @unknown default: break
            }
        }
        .onAppear { base = items.firstIndex(of: selection) ?? 0 }
        .onChange(of: swipe.release) { _, release in
            guard let release else { return }
            let landing = track.nearest(to: track.center(base) - release.predicted, around: base)
            let target = min(max(landing, base - maxStepsPerSwipe), base + maxStepsPerSwipe)
            withAnimation(.snappy) {
                base = target
                swipe.finish()
            }
            commit(item(at: target))
        }
        .onChange(of: selection) { _, newValue in
            guard item(at: base) != newValue, let index = items.firstIndex(of: newValue) else { return }
            var delta = (index - wrapped(base)) % items.count
            if delta > items.count / 2 { delta -= items.count }
            if delta < -items.count / 2 { delta += items.count }
            withAnimation(.snappy) { base += delta }
        }
        .lightOnGlassSystems()
    }

    private func position(on track: PickerTrack) -> CGFloat {
        if isDraggingPicker { return track.center(base) - dragOffset }
        let dragX = track.center(base) - (swipe.isDragging ? swipe.translation : 0)
        return min(max(dragX, track.center(base - maxStepsPerSwipe)), track.center(base + maxStepsPerSwipe))
    }

    private func labels(track: PickerTrack, x: CGFloat, height: CGFloat, span: CGFloat, font: UIFont,
                        color: Color, tappable: Bool) -> some View {
        let middle = track.nearest(to: x, around: base)
        return ZStack {
            ForEach(Array(middle - visibleSpread...middle + visibleSpread), id: \.self) { index in
                Button { select(index) } label: {
                    Text(title(item(at: index)))
                        .font(Font(font))
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .fixedSize()
                        .frame(width: track.slot(index), height: height)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
                .allowsHitTesting(tappable && abs(track.center(index) - x) < width / 2)
                .offset(x: track.center(index) - x)
            }
        }
        .frame(width: span, height: height)
    }

    private func pickerDrag(track: PickerTrack) -> some Gesture {
        DragGesture(minimumDistance: pickerDragMinimum)
            .onChanged { value in
                if !isDraggingPicker {
                    isDraggingPicker = true
                    swipe.holdForPicker(true)
                }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let landing = track.nearest(to: track.center(base) - value.predictedEndTranslation.width, around: base)
                withAnimation(.snappy) {
                    base = landing
                    dragOffset = 0
                    isDraggingPicker = false
                }
                swipe.holdForPicker(false)
                commit(item(at: landing))
            }
    }

    private func wrapped(_ index: Int) -> Int {
        ((index % items.count) + items.count) % items.count
    }

    private func item(at index: Int) -> Item {
        items[wrapped(index)]
    }

    private func select(_ index: Int) {
        withAnimation(.snappy) { base = index }
        commit(item(at: index))
    }

    private func select(item: Item) {
        guard let target = items.firstIndex(of: item) else { return }
        select(base + target - wrapped(base))
    }

    private func commit(_ item: Item) {
        if selection != item { selection = item }
    }
}

private struct PickerTrack {
    private let slots: [CGFloat]
    private let starts: [CGFloat]
    private let cycle: CGFloat

    init(slots: [CGFloat]) {
        self.slots = slots
        var x: CGFloat = 0
        starts = slots.map { width in
            defer { x += width }
            return x
        }
        cycle = x
    }

    func slot(_ index: Int) -> CGFloat {
        slots[wrapped(index)]
    }

    func center(_ index: Int) -> CGFloat {
        let i = wrapped(index)
        let lap = CGFloat((index - i) / slots.count)
        return lap * cycle + starts[i] + slots[i] / 2
    }

    func nearest(to x: CGFloat, around index: Int) -> Int {
        (index - 16...index + 16).min { abs(center($0) - x) < abs(center($1) - x) } ?? index
    }

    func slotWidth(at x: CGFloat, around index: Int) -> CGFloat {
        var left = nearest(to: x, around: index)
        if center(left) > x { left -= 1 }
        let a = center(left), b = center(left + 1)
        let t = min(max((x - a) / (b - a), 0), 1)
        return slot(left) + (slot(left + 1) - slot(left)) * t
    }

    private func wrapped(_ index: Int) -> Int {
        ((index % slots.count) + slots.count) % slots.count
    }
}

#Preview {
    struct Demo: View {
        @State private var part = FacePart.face
        @State private var swipe = PickerSwipe()

        var body: some View {
            ZStack {
                LinearGradient(colors: [.pink, .brown], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                HorizontalPicker(items: FacePart.allCases, selection: $part, swipe: swipe) {
                    $0.title.uppercased()
                }
            }
            .pickerSwipe(swipe)
        }
    }
    return Demo()
}
