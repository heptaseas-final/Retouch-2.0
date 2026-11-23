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
    private(set) var needsDetectionHelp = false

    var selectedPart: FacePart
    var lightMode: LightMode = .off
    var isVoiceOverOn = false

    @ObservationIgnored private let autoPart: FacePart
    @ObservationIgnored private let onFinish: () -> Void
    @ObservationIgnored private let analytics: OnboardingAnalyticsRecording
    @ObservationIgnored private var delayTask: Task<Void, Never>?
    @ObservationIgnored private var helpTask: Task<Void, Never>?
    @ObservationIgnored private var isArmed = false
    @ObservationIgnored private var hasStarted = false

    @ObservationIgnored private let firstStep: OnboardingStep

    init(autoPart: FacePart = .face, analytics: OnboardingAnalyticsRecording, startingAt firstStep: OnboardingStep = .placeHand,
         onFinish: @escaping () -> Void) {
        self.autoPart = autoPart
        self.firstStep = firstStep
        self.selectedPart = autoPart
        self.analytics = analytics
        self.onFinish = onFinish
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        analytics.onboardingStarted()
        enter(firstStep)
    }

    func attach(_ source: any OnboardingSignalSource) {
        source.onSignal = { [weak self] trigger in
            self?.receive(trigger)
        }
    }

    func detach(_ source: any OnboardingSignalSource) {
        source.onSignal = nil
    }

    var instruction: String? {
        needsDetectionHelp ? OnboardingStep.detectionHelp : step.instruction
    }

    var spokenInstruction: String? {
        needsDetectionHelp ? OnboardingStep.detectionHelp : step.spokenInstruction
    }

    var isBubbleVisible: Bool { isInstructionVisible || needsDetectionHelp }

    func skip() {
        guard !isFinished else { return }
        analytics.onboardingSkipped(step: step.analyticsName)
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

    func clipStateChanged(from old: OnboardingClipState, to new: OnboardingClipState) {
        if old == .previewing, new != .previewing {
            receive(.recordingClosed)
        }
        switch new {
        case .recorded: receive(.overallRecorded)
        case .previewing: receive(.recordingOpened)
        case .empty: break
        }
    }

    func nextLightMode(from mode: LightMode) -> LightMode {
        step.lightModeAfterTap ?? mode.next
    }

    func receive(_ trigger: OnboardingTrigger) {
        guard !isFinished else { return }

        if step.revealTrigger == trigger {
            isInstructionVisible = true
        }
        if step.advance.trigger == trigger, step.waitsForDetection {
            stopDetectionHelp()
        }

        guard step.advance.trigger == trigger, !isArmed else { return }
        armAdvance()
    }

    private func enter(_ newStep: OnboardingStep) {
        delayTask?.cancel()
        stopDetectionHelp()
        step = newStep
        if newStep == .overallIntro { selectedPart = autoPart }
        isArmed = false
        isInstructionVisible = newStep.revealTrigger == nil

        if newStep.advance.trigger == nil {
            armAdvance()
        }
        if newStep.waitsForDetection {
            scheduleDetectionHelp()
        }
    }

    private func scheduleDetectionHelp() {
        helpTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(OnboardingStep.detectionHelpDelay))
            guard !Task.isCancelled else { return }
            self?.needsDetectionHelp = true
        }
    }

    private func stopDetectionHelp() {
        helpTask?.cancel()
        helpTask = nil
        needsDetectionHelp = false
    }

    private func armAdvance() {
        isArmed = true
        let delay = step.advance.delay
        scheduleAdvance(after: isVoiceOverOn && step.holdsForVoiceOver ? max(delay, OnboardingStep.voiceOverPause) : delay)
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
            analytics.onboardingCompleted()
            finish()
            return
        }
        analytics.onboardingStepCompleted(step: step.analyticsName, index: step.analyticsIndex)
        enter(next)
    }

    private func finish() {
        guard !isFinished else { return }
        delayTask?.cancel()
        stopDetectionHelp()
        isFinished = true
        onFinish()
    }
}
