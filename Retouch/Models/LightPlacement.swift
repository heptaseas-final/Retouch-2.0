enum LightPlacement: String, CaseIterable {
    case right, bottom, left

    var title: String {
        switch self {
        case .right: "Right"
        case .bottom: "Bottom"
        case .left: "Left"
        }
    }

    var symbol: String {
        switch self {
        case .right: "arrow.right.to.line"
        case .bottom: "arrow.down.to.line"
        case .left: "arrow.left.to.line"
        }
    }
}
