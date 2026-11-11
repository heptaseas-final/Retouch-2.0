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
    let title: (Item) -> String

    @State private var base = 0

    private let maxStepsPerSwipe = 1

    var body: some View {
        let track = PickerTrack(slots: items.map { pickerTextWidth(title($0)) + 2 * padding })
        let dragX = track.center(base) - (swipe.isDragging ? swipe.translation : 0)
        let x = min(max(dragX, track.center(base - maxStepsPerSwipe)), track.center(base + maxStepsPerSwipe))
        let current = track.nearest(to: x, around: base)
        let capsuleWidth = swipe.isDragging ? track.slotWidth(at: x, around: base) : track.slot(base)
        let currentHeight = swipe.isDragging ? expandedHeight : height

        ZStack {
            Color.clear
                .pickerGlass(tint: nil)

            Color.clear
                .pickerGlass(tint: .white.opacity(0.4))
                .frame(width: capsuleWidth, height: currentHeight)

            ForEach(Array(current - 5...current + 5), id: \.self) { index in
                Text(title(item(at: index)))
                    .font(Font(pickerFont))
                    .foregroundStyle(index == current ? Color.appMagenta : Color.appInactive.opacity(0.6))
                    .lineLimit(1)
                    .fixedSize()
                    .frame(width: track.slot(index), height: currentHeight)
                    .contentShape(Rectangle())
                    .onTapGesture { select(index) }
                    .allowsHitTesting(abs(track.center(index) - x) < width / 2)
                    .offset(x: track.center(index) - x)
            }
        }
        .frame(width: width, height: currentHeight)
        .clipShape(Capsule())
        .contentShape(Capsule())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: swipe.isDragging)
        .sensoryFeedback(.selection, trigger: current)
        .accessibilityElement()
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Zoom target")
        .accessibilityValue(title(selection))
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

    private func commit(_ item: Item) {
        if selection != item { selection = item }
    }
}

private let pickerFont: UIFont = {
    let regular = UIFont.systemFont(ofSize: 15, weight: .regular)
    guard let rounded = regular.fontDescriptor.withDesign(.rounded) else { return regular }
    return UIFont(descriptor: rounded, size: 15)
}()

private func pickerTextWidth(_ text: String) -> CGFloat {
    ceil((text as NSString).size(withAttributes: [.font: pickerFont]).width)
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
        (index - 8...index + 8).min { abs(center($0) - x) < abs(center($1) - x) } ?? index
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

@MainActor @Observable
final class PickerSwipe {
    struct Release: Equatable {
        let id = UUID()
        let predicted: CGFloat
    }

    fileprivate(set) var translation: CGFloat = 0
    fileprivate(set) var isDragging = false
    fileprivate(set) var release: Release?

    fileprivate func update(_ dx: CGFloat) {
        translation = dx
        isDragging = true
    }

    fileprivate func end(predicted dx: CGFloat) {
        guard isDragging else { return }
        release = Release(predicted: dx)
    }

    fileprivate func finish() {
        isDragging = false
        translation = 0
        release = nil
    }

    fileprivate func cancel() {
        guard isDragging else { return }
        withAnimation(.snappy) { finish() }
    }
}

private struct PickerSwipeGesture: ViewModifier {
    let swipe: PickerSwipe
    let isEnabled: Bool

    @State private var axis: Axis?
    @State private var isPinching = false

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(drag, including: isEnabled ? .all : .subviews)
            .simultaneousGesture(pinch, including: isEnabled ? .all : .subviews)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if axis == nil {
                    axis = abs(value.translation.width) > abs(value.translation.height) ? .horizontal : .vertical
                }
                guard axis == .horizontal, !isPinching else { return }
                swipe.update(value.translation.width)
            }
            .onEnded { value in
                defer {
                    axis = nil
                    isPinching = false
                }
                guard axis == .horizontal, !isPinching else {
                    swipe.cancel()
                    return
                }
                swipe.end(predicted: value.predictedEndTranslation.width)
            }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { _ in
                isPinching = true
                swipe.cancel()
            }
            .onEnded { _ in
                if axis == nil { isPinching = false }
            }
    }
}

extension View {
    func pickerSwipe(_ swipe: PickerSwipe, isEnabled: Bool = true) -> some View {
        modifier(PickerSwipeGesture(swipe: swipe, isEnabled: isEnabled))
    }
}

private extension View {
    @ViewBuilder
    func pickerGlass(tint: Color?) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.tint(tint), in: Capsule())
        } else {
            background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().fill(tint ?? .clear))
        }
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
