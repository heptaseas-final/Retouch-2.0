//
//  ToolGripVerifier.swift
//  Retouch
//
//  Created by Davin P on 19/11/26.
//

import CoreGraphics
import Foundation

nonisolated struct ToolGripPose: Equatable {
    var grip: CGPoint
    var tip: CGPoint
}

nonisolated struct ToolGripVerifier {
    private(set) var grips: [ToolGripPose] = []
    private(set) var handsSeen = 0
    private(set) var time = Date.distantPast
    private var tips: [CGPoint] = []

    mutating func note(fingertips: [CGPoint], grips: [ToolGripPose], handsSeen: Int, at now: Date) {
        tips = fingertips
        self.grips = grips
        self.handsSeen = handsSeen
        time = now
    }

    mutating func reset() {
        tips = []
        grips = []
        handsSeen = 0
        time = .distantPast
    }

    func isFresh(at now: Date) -> Bool {
        abs(now.timeIntervalSince(time)) <= ToolDetectionTuning.handMaxAge
    }

    func tipHint(of tool: TrackedTool, faceWidth: CGFloat, at now: Date) -> CGPoint? {
        guard isFresh(at: now) else { return nil }
        let grown = tool.rect.insetBy(dx: -ToolDetectionTuning.gripMargin * faceWidth,
                                      dy: -ToolDetectionTuning.gripMargin * faceWidth)
        return grips.filter { grown.contains($0.grip) }
            .min { hypot($0.grip.x - tool.rect.midX, $0.grip.y - tool.rect.midY)
                < hypot($1.grip.x - tool.rect.midX, $1.grip.y - tool.rect.midY) }?.tip
    }

    func grip(of tool: TrackedTool, faceWidth: CGFloat, at now: Date) -> CGPoint? {
        guard !tips.isEmpty, isFresh(at: now) else { return nil }
        let grown = tool.rect.insetBy(dx: -ToolDetectionTuning.gripMargin * faceWidth,
                                      dy: -ToolDetectionTuning.gripMargin * faceWidth)
        let inside = tips.filter { grown.contains($0) }
        guard !inside.isEmpty else { return nil }
        let count = CGFloat(inside.count)
        return CGPoint(x: inside.reduce(0) { $0 + $1.x } / count, y: inside.reduce(0) { $0 + $1.y } / count)
    }
}
