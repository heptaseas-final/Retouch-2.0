enum LightPlacement: String, CaseIterable {
    case right, bottom, left

    var title: String {
        switch self {
        case .right: "Light Button: Right"
        case .bottom: "Light Button: Bottom"
        case .left: "Light Button: Left"
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
