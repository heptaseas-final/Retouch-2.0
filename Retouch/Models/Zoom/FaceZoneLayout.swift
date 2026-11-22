import Foundation

nonisolated enum FaceZoneLayout: Equatable, Sendable {
    case frontal
    case turned(visibleSide: FaceSide)
}
