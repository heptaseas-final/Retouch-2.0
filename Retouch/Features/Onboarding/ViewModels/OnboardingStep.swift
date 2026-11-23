import Foundation

enum OnboardingTrigger: Hashable {
    case handNearEye
    case zoomedIn
    case modeSelected
    case flashTapped
}

struct OnboardingAdvance: Equatable {
    var trigger: OnboardingTrigger?
    var delay: TimeInterval

    static func on(_ trigger: OnboardingTrigger, thenWait delay: TimeInterval = 0) -> OnboardingAdvance {
        OnboardingAdvance(trigger: trigger, delay: delay)
    }

    static func after(_ delay: TimeInterval) -> OnboardingAdvance {
        OnboardingAdvance(trigger: nil, delay: delay)
    }
}

enum OnboardingFocus {
    case none, picker, flash, lightColor

    var isLighting: Bool { self == .flash || self == .lightColor }
}

enum OnboardingBubblePosition {
    case top, bottom
}

enum OnboardingStep: CaseIterable {
    case placeHand
    case retouchKnows
    case noNeedToTap
    case swipeModes
    case zoomedOnArea
    case needLight
    case tapForWarm
    case tapForCool
    case tapForWhite
    case tapToTurnOff
    case done

    static let pause: TimeInterval = 3.5
    static let voiceOverPause: TimeInterval = 4
    static let detectionHelpDelay: TimeInterval = 8
    static let detectionHelp = "Can't see your hand yet. Keep your face in view and bring your hand closer to the area you want to retouch."

    var waitsForDetection: Bool {
        advance.trigger == .handNearEye || advance.trigger == .zoomedIn
    }

    var instruction: String? {
        switch self {
        case .placeHand:     "Place your hand or makeup product near the area you want to retouch."
        case .retouchKnows:  "Retouch knows what you’re working on,"
        case .noNeedToTap:   "so you don’t have to tap anything on screen."
        case .swipeModes:    "Swipe between modes to lock onto an area."
        case .zoomedOnArea:  nil
        case .needLight:     "Need more light? Tap here for lighting."
        case .tapForWarm:    "Tap to see warm light."
        case .tapForCool:    "Tap again to see cool light."
        case .tapForWhite:   "Tap again to go back to neutral light."
        case .tapToTurnOff:  "Tap here to turn off the light."
        case .done:          "Happy Retouch-ing!"
        }
    }

    var spokenInstruction: String? {
        switch self {
        case .swipeModes:    "Swipe up or down on Zoom target to switch modes and lock onto an area."
        case .zoomedOnArea:  "Zoom is locked on this area. Take a look."
        case .needLight:     "Need more light? Double tap the Light button."
        case .tapForWarm:    "Double tap Light color to see warm light."
        case .tapForCool:    "Double tap Light color again to see cool light."
        case .tapForWhite:   "Double tap Light color again to go back to neutral light."
        case .tapToTurnOff:  "Double tap the Light button to turn off the light."
        default:             instruction
        }
    }

    var revealTrigger: OnboardingTrigger? {
        self == .retouchKnows ? .zoomedIn : nil
    }

    var advance: OnboardingAdvance {
        switch self {
        case .placeHand:     .on(.handNearEye)
        case .retouchKnows:  .on(.zoomedIn, thenWait: Self.pause)
        case .noNeedToTap:   .after(Self.pause)
        case .swipeModes:    .on(.modeSelected)
        case .zoomedOnArea:  .after(Self.pause)
        case .needLight, .tapForWarm, .tapForCool, .tapForWhite, .tapToTurnOff:
                             .on(.flashTapped)
        case .done:          .after(Self.pause)
        }
    }

    var focus: OnboardingFocus {
        switch self {
        case .swipeModes: .picker
        case .needLight, .tapToTurnOff: .flash
        case .tapForWarm, .tapForCool, .tapForWhite: .lightColor
        default: .none
        }
    }
    var dimsBackdrop: Bool {
        switch self {
        case .swipeModes, .needLight, .tapForWarm, .tapToTurnOff: true
        default: false
        }
    }

    var bubblePosition: OnboardingBubblePosition {
        switch self {
        case .placeHand, .retouchKnows, .noNeedToTap: .top
        default: .bottom
        }
    }

    var lightModeAfterTap: LightMode? {
        switch self {
        case .needLight:     LightMode.on(.white)
        case .tapForWarm:    LightMode.on(.warm)
        case .tapForCool:    LightMode.on(.cool)
        case .tapForWhite:   LightMode.on(.white)
        case .tapToTurnOff:  LightMode.off
        default:             nil
        }
    }

    var next: OnboardingStep? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self), index + 1 < all.count else { return nil }
        return all[index + 1]
    }
}
