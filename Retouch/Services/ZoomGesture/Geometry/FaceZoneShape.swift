import CoreGraphics

nonisolated struct FaceZoneShape {
    let vertices: [CGPoint]
    private let center: CGPoint

    init(vertices: [CGPoint]) {
        self.vertices = vertices
        let count = CGFloat(max(vertices.count, 1))
        center = CGPoint(x: vertices.reduce(0) { $0 + $1.x } / count,
                         y: vertices.reduce(0) { $0 + $1.y } / count)
    }

    func contains(_ p: CGPoint, grownBy factor: CGFloat = 1) -> Bool {
        guard vertices.count >= 3, factor > 0 else { return false }
        let q = CGPoint(x: center.x + (p.x - center.x) / factor, y: center.y + (p.y - center.y) / factor)
        var inside = false
        var previous = vertices[vertices.count - 1]
        for current in vertices {
            if (current.y > q.y) != (previous.y > q.y) {
                let crossing = (previous.x - current.x) * (q.y - current.y) / (previous.y - current.y) + current.x
                if q.x < crossing { inside.toggle() }
            }
            previous = current
        }
        return inside
    }
}
