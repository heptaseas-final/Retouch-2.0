import SwiftUI

struct PickerLens: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        if #available(iOS 26, *) {
            Color.clear
                .frame(width: width, height: height)
                .glassEffect(.clear, in: Capsule())
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
