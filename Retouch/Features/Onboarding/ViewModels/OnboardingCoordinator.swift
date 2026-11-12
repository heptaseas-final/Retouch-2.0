//
//  OnboardingCoordinator.swift
//  Retouch
//
//  Created by Gabriella Angelina Widjaja on 06/11/26.
//

import SwiftUI
import Observation
import Foundation

@Observable
final class OnboardingCoordinator {

    private(set) var step: OnboardingStep = .placeHand
    private(set) var isInstructionVisible = true
    private(set) var isFinished = false

    var selectedPart: FacePart
    var lightMode: LightMode = .off
    var isVoiceOverOn = false

    @ObservationIgnored private let autoPart: FacePart
    @ObservationIgnored private let onFinish: () -> Void
    @ObservationIgnored private var delayTask: Task<Void, Never>?
    @ObservationIgnored private var isArmed = false
    @ObservationIgnored private var hasStarted = false

    init(autoPart: FacePart = .face, onFinish: @escaping () -> Void) {
        self.autoPart = autoPart
        self.selectedPart = autoPart
        self.onFinish = onFinish
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        enter(.placeHand)
    }

    func attach(_ source: any OnboardingSignalSource) {
        source.onSignal = { [weak self] trigger in
            self?.receive(trigger)
        }
    }

    func detach(_ source: any OnboardingSignalSource) {
        source.onSignal = nil
    }

    func skip() {
        finish()
    }

    func selectPart(_ part: FacePart) {
        selectedPart = part
        if part != autoPart {
            receive(.modeSelected)
        }
    }

    func flashTapped() {
        receive(.flashTapped)
    }

    func nextLightMode(from mode: LightMode) -> LightMode {
        step.lightModeAfterTap ?? mode.next
    }

    func receive(_ trigger: OnboardingTrigger) {
        guard !isFinished else { return }

        if step.revealTrigger == trigger {
            isInstructionVisible = true
        }

        guard step.advance.trigger == trigger, !isArmed else { return }
        armAdvance()
    }

    private func enter(_ newStep: OnboardingStep) {
        delayTask?.cancel()
        step = newStep
        isArmed = false
        isInstructionVisible = newStep.revealTrigger == nil

        if newStep.advance.trigger == nil {
            armAdvance()
        }
    }

    private func armAdvance() {
        isArmed = true
        let delay = step.advance.delay
        scheduleAdvance(after: isVoiceOverOn && delay > 0 ? max(delay, OnboardingStep.voiceOverPause) : delay)
    }

    private func scheduleAdvance(after delay: TimeInterval) {
        delayTask?.cancel()
        guard delay > 0 else {
            advance()
            return
        }
        delayTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            self?.advance()
        }
    }

    private func advance() {
        guard let next = step.next else {
            finish()
            return
        }
        enter(next)
    }

    private func finish() {
        guard !isFinished else { return }
        delayTask?.cancel()
        isFinished = true
        onFinish()
    }
}

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

    static let pause: TimeInterval = 2.5
    static let voiceOverPause: TimeInterval = 4

    var instruction: String? {
        switch self {
        case .placeHand:     "Place your hand or makeup product near the area you want to retouch."
        case .retouchKnows:  "Retouch knows what you’re working on,"
        case .noNeedToTap:   "so you don’t have to tap anything on screen."
        case .swipeModes:    "Swipe left or right to switch modes and focus on one area."
        case .zoomedOnArea:  nil
        case .needLight:     "Need more light? Tap the light button."
        case .tapForWarm:    "Tap to see warm light."
        case .tapForCool:    "Tap again to see cool light."
        case .tapForWhite:   "Tap again to go back to neutral light."
        case .tapToTurnOff:  "Tap the light button to turn it off."
        case .done:          "Happy Retouch-ing!"
        }
    }

    var spokenInstruction: String? {
        switch self {
        case .swipeModes:    "Swipe up or down on Zoom target to switch modes and focus on one area."
        case .needLight:     "Need more light? Double tap the Light button."
        case .tapForWarm:    "Double tap Light color to see warm light."
        case .tapForCool:    "Double tap Light color again to see cool light."
        case .tapForWhite:   "Double tap Light color again to go back to neutral light."
        case .tapToTurnOff:  "Double tap the Light button to turn it off."
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

    var showsHandOverlay: Bool { self == .placeHand }
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
