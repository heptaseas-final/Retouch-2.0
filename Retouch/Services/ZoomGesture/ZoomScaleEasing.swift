//
//  ZoomScaleEasing.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 20/11/26.
//


import CoreGraphics

nonisolated enum ZoomScaleEasing {
    static func easesAfterGoal(wasEasing: Bool, wasOverall: Bool, isOverall: Bool, modeChanged: Bool) -> Bool {
        if wasOverall != isOverall { return true }
        return modeChanged ? false : wasEasing
    }

    static func easedStep(current: CGFloat, goal: CGFloat, velocity: inout CGFloat,
                          smoothTime: CGFloat, dt: CGFloat) -> CGFloat {
        let omega = 2 / max(smoothTime, 0.0001)
        let x = omega * dt
        let e = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
        let change = current - goal
        let temp = (velocity + omega * change) * dt
        velocity = (velocity - omega * temp) * e
        return goal + (change + temp) * e
    }

    static func isSettled(current: CGFloat, goal: CGFloat, velocity: CGFloat) -> Bool {
        abs(goal - current) < 0.0005 && abs(velocity) < 0.001
    }
}