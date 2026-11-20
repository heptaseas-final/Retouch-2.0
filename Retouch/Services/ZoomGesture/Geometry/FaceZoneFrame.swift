import CoreGraphics

nonisolated struct FaceZoneFrame {
    let leftEyeX: CGFloat
    let rightEyeX: CGFloat
    let leftEdgeX: CGFloat
    let rightEdgeX: CGFloat
    let noseOffset: CGFloat?

    private let origin: CGPoint
    private let across: CGPoint
    private let down: CGPoint
    private let unit: CGFloat
    private let depth: CGFloat

    init?(points: FacePoints) {
        guard let left = points.leftEye, let right = points.rightEye, points.scale > 0 else { return nil }
        let length = hypot(right.x - left.x, right.y - left.y)
        guard length > 0 else { return nil }
        let origin = CGPoint(x: (left.x + right.x) / 2, y: (left.y + right.y) / 2)
        let across = CGPoint(x: (right.x - left.x) / length, y: (right.y - left.y) / length)
        let down = CGPoint(x: -across.y, y: across.x)
        let unit = points.scale

        func along(_ p: CGPoint) -> CGFloat { ((p.x - origin.x) * across.x + (p.y - origin.y) * across.y) / unit }
        func below(_ p: CGPoint) -> CGFloat { ((p.x - origin.x) * down.x + (p.y - origin.y) * down.y) / unit }

        let measuredDepth = points.lipsTop.map(below) ?? FaceZoneConfig.defaultDepth
        let centerX = points.center.map(along) ?? 0
        let halfWidth = points.width > 0 ? points.width / 2 / unit : FaceZoneConfig.defaultHalfWidth

        self.origin = origin
        self.across = across
        self.down = down
        self.unit = unit
        depth = min(max(measuredDepth, FaceZoneConfig.minDepth), FaceZoneConfig.maxDepth)
        leftEyeX = -length / 2 / unit
        rightEyeX = length / 2 / unit
        leftEdgeX = centerX - halfWidth
        rightEdgeX = centerX + halfWidth
        noseOffset = points.nose.map(along)
    }

    func view(x: CGFloat, y: CGFloat) -> CGPoint {
        let a = x * unit
        let b = y * unit * depth
        return CGPoint(x: origin.x + across.x * a + down.x * b,
                       y: origin.y + across.y * a + down.y * b)
    }
}
