
import CoreGraphics

nonisolated enum FaceZoneTemplate {
    typealias Entry = (zone: FaceZone, shape: FaceZoneShape)

    static func shapes(for layout: FaceZoneLayout, frame: FaceZoneFrame) -> [Entry] {
        switch layout {
        case .frontal: frontal(frame)
        case .turned(let visibleSide): turned(visibleSide, frame)
        }
    }

    private static func frontal(_ frame: FaceZoneFrame) -> [Entry] {
        let leftEdge = max(-frame.leftEdgeX, FaceZoneConfig.frontalMinEdge)
        let rightEdge = max(frame.rightEdgeX, FaceZoneConfig.frontalMinEdge)
        var entries: [Entry] = [
            (FaceZone.lips, shape(FaceZoneConfig.frontalLips, frame, originX: 0, direction: 1, edge: 0)),
            (FaceZone.leftEye, shape(FaceZoneConfig.frontalEye, frame, originX: 0, direction: -1, edge: leftEdge)),
            (FaceZone.rightEye, shape(FaceZoneConfig.frontalEye, frame, originX: 0, direction: 1, edge: rightEdge)),
            (FaceZone.nose, shape(FaceZoneConfig.frontalNose, frame, originX: 0, direction: 1, edge: 0))
        ]
        if FaceZoneConfig.frontalCheekEnabled {
            entries.append((FaceZone.leftCheek, shape(FaceZoneConfig.frontalCheek, frame, originX: 0, direction: -1,
                                              edge: leftEdge)))
            entries.append((FaceZone.rightCheek, shape(FaceZoneConfig.frontalCheek, frame, originX: 0, direction: 1,
                                               edge: rightEdge)))
        }
        return entries
    }

    private static func turned(_ visibleSide: FaceSide, _ frame: FaceZoneFrame) -> [Entry] {
        let isRight = visibleSide == .right
        let direction: CGFloat = isRight ? 1 : -1
        let eyeX = isRight ? frame.rightEyeX : frame.leftEyeX
        let reach = isRight ? frame.rightEdgeX - eyeX : eyeX - frame.leftEdgeX
        let edge = max(reach, FaceZoneConfig.turnedMinEdge)
        return [
            (isRight ? FaceZone.rightEye : FaceZone.leftEye,
             shape(FaceZoneConfig.turnedEye, frame, originX: eyeX, direction: direction, edge: edge)),
            (FaceZone.nose, shape(FaceZoneConfig.turnedNose, frame, originX: eyeX, direction: direction, edge: edge)),
            (isRight ? FaceZone.rightCheek : FaceZone.leftCheek,
             shape(FaceZoneConfig.turnedCheek, frame, originX: eyeX, direction: direction, edge: edge))
        ]
    }

    private static func shape(_ points: [FaceZonePoint], _ frame: FaceZoneFrame, originX: CGFloat,
                              direction: CGFloat, edge: CGFloat) -> FaceZoneShape {
        FaceZoneShape(vertices: points.map { point in
            let x = point.fromEdge ? edge + point.x : point.x
            return frame.view(x: originX + direction * x, y: point.y)
        })
    }
}
