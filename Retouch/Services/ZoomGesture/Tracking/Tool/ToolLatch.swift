//
//  ToolLatch.swift
//  Retouch
//
//  Created by Davin P on 20/11/26.
//


//
//  ToolLatch.swift
//  Retouch
//
//  Created by Davin P on 20/11/26.
//

import CoreGraphics
import Foundation

nonisolated struct ToolLatch {
    private(set) var isLatched = false
    private var point = CGPoint.zero
    private var pose: ToolGripPose?
    private var confirmedAt = Date.distantPast
    private var gripSeenAt = Date.distantPast
    private var handSeenAt = Date.distantPast

    mutating func confirm(grip: CGPoint, at now: Date) {
        if !isLatched {
            gripSeenAt = now
            handSeenAt = now
        }
        isLatched = true
        point = grip
        confirmedAt = now
    }

    mutating func reset() {
        isLatched = false
        pose = nil
        confirmedAt = .distantPast
        gripSeenAt = .distantPast
        handSeenAt = .distantPast
    }

    mutating func update(_ verifier: ToolGripVerifier, faceWidth: CGFloat, now: Date) -> ToolGripPose? {
        guard isLatched else { return nil }
        guard now.timeIntervalSince(confirmedAt) <= ToolDetectionTuning.latchSafety, faceWidth > 0 else {
            reset()
            return nil
        }
        let fresh = verifier.isFresh(at: now)
        if fresh {
            let radius = ToolDetectionTuning.latchMatchRadius * faceWidth
            let match = verifier.grips
                .filter { hypot($0.grip.x - point.x, $0.grip.y - point.y) <= radius }
                .min { hypot($0.grip.x - point.x, $0.grip.y - point.y)
                    < hypot($1.grip.x - point.x, $1.grip.y - point.y) }
            if verifier.handsSeen > 0 { handSeenAt = now }
            if let match {
                point = match.grip
                pose = match
                gripSeenAt = now
                return match
            }
            if verifier.handsSeen > 0, now.timeIntervalSince(gripSeenAt) > ToolDetectionTuning.latchOpenAfter {
                reset()
                return nil
            }
        }
        guard now.timeIntervalSince(handSeenAt) <= ToolDetectionTuning.latchHandLostAfter else {
            reset()
            return nil
        }
        return pose
    }
}