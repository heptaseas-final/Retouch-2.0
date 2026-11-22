import Foundation

enum OnboardingTrigger: Hashable {
    case handNearEye
    case zoomedIn
    case modeSelected
    case flashTapped
    case videoEnded
    case overallRecorded
    case recordingOpened
    case recordingClosed
}

enum OnboardingClipState: Equatable {
    case empty, recorded, previewing
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
    case none, picker, flash, lightColor, recording, preview

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
    case overallIntro
    case overallCheck
    case tapRecording
    case reviewRecording
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
        case .overallIntro:  "Move away from the camera to check your overall look."
        case .overallCheck:  "Step back and twirl to check your 360 look."
        case .tapRecording:  "We will automatically record your looks, tap here to check your look."
        case .reviewRecording: "Review your look closely. Replay, save, or delete your recording anytime."
        case .done:          "Happy Retouch-ing!"
        }
    }

    var spokenInstruction: String? {
        switch self {
        case .swipeModes:    "Swipe up or down on Zoom target to switch modes and lock onto an area."
        case .needLight:     "Need more light? Double tap the Light button."
        case .tapForWarm:    "Double tap Light color to see warm light."
        case .tapForCool:    "Double tap Light color again to see cool light."
        case .tapForWhite:   "Double tap Light color again to go back to neutral light."
        case .tapToTurnOff:  "Double tap the Light button to turn off the light."
        case .tapRecording:  "Double tap the video thumbnail to check your look."
        case .reviewRecording: "Review your look. Play, save, or delete the video, or close the preview."
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
        case .overallIntro:  .on(.videoEnded)
        case .overallCheck:  .on(.overallRecorded)
        case .tapRecording:  .on(.recordingOpened)
        case .reviewRecording: .on(.recordingClosed)
        case .done:          .after(Self.pause)
        }
    }

    var focus: OnboardingFocus {
        switch self {
        case .swipeModes: .picker
        case .needLight, .tapToTurnOff: .flash
        case .tapForWarm, .tapForCool, .tapForWhite: .lightColor
        case .tapRecording: .recording
        case .reviewRecording: .preview
        default: .none
        }
    }
    var dimsBackdrop: Bool {
        switch self {
        case .swipeModes, .needLight, .tapForWarm, .tapToTurnOff, .overallIntro, .tapRecording: true
        default: false
        }
    }

    var bubblePosition: OnboardingBubblePosition {
        switch self {
        case .placeHand, .retouchKnows, .noNeedToTap, .overallCheck, .reviewRecording: .top
        default: .bottom
        }
    }

    var showsRecording: Bool {
        self == .overallCheck || self == .tapRecording || self == .reviewRecording
    }

    var isOverallOnly: Bool {
        self == .overallIntro || showsRecording
    }

    var holdsForVoiceOver: Bool {
        advance.delay > 0 || self == .overallIntro
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
