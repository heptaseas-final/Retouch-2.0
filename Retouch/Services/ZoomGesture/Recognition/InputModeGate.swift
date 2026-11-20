//
//  InputModeGate.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 19/11/26.
//


import Foundation

nonisolated struct InputModeGate {
    enum Presence { case none, weak, strong }

    private(set) var mode: InputMode = .finger
    private var streak = 0
    private var lastSeen: Date?

    mutating func note(_ presence: Presence, at now: Date) {
        switch presence {
        case .none:
            streak = 0
        case .weak:
            streak = 0
            lastSeen = now
        case .strong:
            streak += 1
            lastSeen = now
        }
    }

    @discardableResult
    mutating func update(zoomActive: Bool, now: Date) -> InputMode {
        guard !zoomActive else { return mode }
        let recent = lastSeen.map { now.timeIntervalSince($0) < ToolDetectionTuning.toolModeExitAfter } ?? false
        switch mode {
        case .finger:
            if recent, streak >= ToolDetectionTuning.toolModeEnterStreak { mode = .tool }
        case .tool:
            if !recent {
                mode = .finger
                streak = 0
            }
        }
        return mode
    }

    mutating func reset() {
        mode = .finger
        streak = 0
        lastSeen = nil
    }

    static func presence(of tools: [TrackedTool], face: FacePoints) -> Presence {
        guard face.width > 0, let center = face.center else { return .none }
        var result = Presence.none
        for tool in tools where tool.confidence >= ToolDetectionTuning.minConfidence {
            let tip = ToolTipLocator.tip(of: tool, face: face)
            guard hypot(tip.x - center.x, tip.y - center.y) / face.width <= ToolDetectionTuning.faceAreaRadius
            else { continue }
            if tool.confidence >= ToolDetectionTuning.triggerConfidence { return .strong }
            result = .weak
        }
        return result
    }
}
