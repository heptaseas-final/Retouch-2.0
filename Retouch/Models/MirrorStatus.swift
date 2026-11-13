import Foundation

enum MirrorStatus: CaseIterable, Hashable {
    case cameraPaused
    case phoneWarm
    case notEnoughLight
    case moveCloserInLowLight
    case tooFar
    case faceTooWide
    case enoughLight

    enum Kind {
        case error, success, info
    }

    var message: String {
        switch self {
        case .cameraPaused: "Your camera is temporarily paused"
        case .phoneWarm: "Your phone is getting warm, so we've reduced the screen brightness to help protect it"
        case .notEnoughLight: "Not enough light, move somewhere to ensure your makeup stays visible"
        case .moveCloserInLowLight: "Move a little closer to get a clearer view of your face"
        case .tooFar: "You are too far, move closer to see your face clearly"
        case .faceTooWide: "Hold the phone further away or prop it up to see your face fully"
        case .enoughLight: "You have enough light, happy retouching"
        }
    }

    var kind: Kind {
        switch self {
        case .cameraPaused, .phoneWarm: .info
        case .notEnoughLight, .moveCloserInLowLight, .tooFar: .error
        case .faceTooWide, .enoughLight: .success
        }
    }

    var dwell: TimeInterval {
        switch self {
        case .cameraPaused, .phoneWarm: 0
        default: MirrorStatusConfig.dwell
        }
    }

    var displayTime: TimeInterval? {
        switch self {
        case .enoughLight: MirrorStatusConfig.enoughLightTime
        case .faceTooWide: MirrorStatusConfig.faceTooWideTime
        default: nil
        }
    }
}

struct MirrorStatusInput {
    var isCameraPaused = false
    var isHeatLimited = false
    var faceLux: Double?
    var isLightAtLimit = false
    var faceWidthRatio: Double?
    var zoomScale: Double = 1
}

enum MirrorStatusConfig {
    static let dwell: TimeInterval = 1.5
    static let enoughLightTime: TimeInterval = 2
    static let faceTooWideTime: TimeInterval = 3
    static let lowLux = 300.0
    static let enoughLux = 330.0
    static let closeEnoughRatio = 0.66
    static let tooFarRatio = 0.44
    static let zoomedScale = 2.0
    static let fullViewScale = 1.2
    static let faceTooWideRatio = 1.0
    static let refreshInterval: Duration = .milliseconds(250)
}
