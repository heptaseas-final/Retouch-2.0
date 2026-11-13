import Foundation

enum CameraState: Equatable {
    case idle
    case notDetermined
    case permissionDenied
    case starting
    case running
    case reconnecting
    case failed
}

struct LightingStatus: Equatable {
    var faceLux: Double?
    var isGlowAtMax = false
    var isHeatLimited = false
}

enum ManualColorChoice: String, CaseIterable {
    case warm, natural, cool
}

nonisolated enum CameraPermissionStatus {
    case notDetermined, granted, denied
}
