import SwiftUI

struct SpotlightShape: Shape {
    var hole: CGRect?
    var animatesHole = true

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            guard animatesHole else { return .zero }
            let r = hole ?? .zero
            return AnimatablePair(AnimatablePair(r.midX, r.midY), AnimatablePair(r.width, r.height))
        }
        set {
            guard animatesHole, hole != nil else { return }
            hole = CGRect(x: newValue.first.first - newValue.second.first / 2,
                          y: newValue.first.second - newValue.second.second / 2,
                          width: newValue.second.first, height: newValue.second.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path(rect.insetBy(dx: -1000, dy: -1000))
        if let hole {
            path.addRoundedRect(in: hole, cornerSize: CGSize(width: min(hole.width, hole.height) / 2,
                                                             height: min(hole.width, hole.height) / 2))
        }
        return path
    }
}
