import SwiftUI

struct GlowHoleShape: Shape {
    var holeScale: CGSize

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(holeScale.width, holeScale.height) }
        set { holeScale = CGSize(width: newValue.first, height: newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let width = rect.width * holeScale.width
        let height = rect.height * holeScale.height
        let hole = CGRect(x: rect.midX - width / 2, y: rect.midY - height / 2, width: width, height: height)
        let corner = CGSize(width: GlowFrame.holeCornerRadius, height: GlowFrame.holeCornerRadius)
        var path = Path(rect)
        path.addRoundedRect(in: hole, cornerSize: corner, style: .continuous)
        return path
    }
}
