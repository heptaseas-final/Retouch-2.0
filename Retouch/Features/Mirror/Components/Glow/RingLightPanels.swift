import SwiftUI

struct RingLightPanels: View {
    let progress: CGFloat
    let isOverall: Bool
    let opacity: Double
    let color: Color

    @State private var size: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GlowHoleShape(holeScale: GlowFrame.holeScale(in: size, progress: reduceMotion ? 1 : progress, isOverall: isOverall))
            .fill(color, style: FillStyle(eoFill: true))
            .transaction { if reduceMotion { $0.animation = nil } }
            .opacity(opacity)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
