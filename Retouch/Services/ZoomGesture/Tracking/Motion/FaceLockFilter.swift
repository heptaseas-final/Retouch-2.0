//
//  FaceLockFilter.swift
//  Retouch
//
//  Created by Retouch Team on 23/11/26.
//

import CoreGraphics
import Foundation

nonisolated struct FaceLockFilter {
    struct Detection: Equatable {
        var center: CGPoint
        var width: CGFloat
        var roll: CGFloat? = nil
    }

    private(set) var position: CGPoint?
    private(set) var width: CGFloat = 0
    private(set) var weight: CGFloat = 0
    private var anchor: CGPoint = .zero
    private var entry: CGPoint = .zero
    private var anchorWidth: CGFloat = 0
    private var anchorScale: CGFloat = 1
    private var roll: CGFloat = 0
    private var lostFor: TimeInterval = 0
    private var pose: FaceLockPose?
    private var clock: TimeInterval = 0
    private var centerXSmoother = FaceLockFilter.smoother(ZoomTuning.faceLockCenterMinCutoff, ZoomTuning.faceLockCenterBeta)
    private var centerYSmoother = FaceLockFilter.smoother(ZoomTuning.faceLockCenterMinCutoff, ZoomTuning.faceLockCenterBeta)
    private var widthSmoother = FaceLockFilter.smoother(ZoomTuning.faceLockWidthMinCutoff, ZoomTuning.faceLockWidthBeta)
    private var rollSmoother = FaceLockFilter.smoother(ZoomTuning.faceLockRollMinCutoff, ZoomTuning.faceLockRollBeta)

    var isEngaged: Bool { weight > ZoomTuning.faceLockMinWeight }

    mutating func update(active: Bool, detection: Detection?, flow: CGVector?, canEngage: Bool,
                         dt: TimeInterval) -> FaceLockPose? {
        let step = min(max(dt, 0), ZoomTuning.faceLockMaxStep)
        clock += step
        guard active else { return release(step: step) }
        if position == nil {
            guard canEngage, let detection, detection.width > 0 else { return release(step: step) }
            position = detection.center
            width = detection.width
            anchor = CGPoint(x: ZoomTuning.faceLockAnchorX, y: ZoomTuning.faceLockAnchorY)
            entry = detection.center
            anchorWidth = detection.width
            anchorScale = ZoomTuning.fullFaceZoom
            roll = Self.limitedRoll(detection.roll ?? 0)
            lostFor = 0
        }
        guard var current = position else { return release(step: step) }

        if let flow {
            current.x += flow.dx
            current.y += flow.dy
        }
        if let found = detection, found.width > 0 {
            let detection = smoothed(found)
            lostFor = 0
            let tau = flow == nil ? ZoomTuning.faceLockSnapTau : ZoomTuning.faceLockTrackTau
            let gain = CGFloat(1 - exp(-step / tau))
            current.x += (detection.center.x - current.x) * gain
            current.y += (detection.center.y - current.y) * gain
            width += (detection.width - width) * CGFloat(1 - exp(-step / ZoomTuning.faceLockWidthTau))
            if let tilt = detection.roll {
                let turn = atan2(sin(tilt - roll), cos(tilt - roll))
                roll = Self.limitedRoll(roll + turn * CGFloat(1 - exp(-step / ZoomTuning.faceLockRollTau)))
            }
        } else {
            lostFor += step
        }
        position = current
        guard lostFor < ZoomTuning.faceLockLostHold else { return release(step: step) }

        weight += (1 - weight) * CGFloat(1 - exp(-step / ZoomTuning.faceLockEngageTau))
        let raw = Self.softenedRatio(anchorWidth / max(width, 0.0001))
        let ratio = ZoomTuning.faceLockFollowsDistance
            ? min(max(raw, ZoomTuning.faceLockMinSizeRatio), ZoomTuning.faceLockMaxSizeRatio)
            : 1
        let locked = FaceLockPose(face: current, entry: entry, anchor: anchor, anchorScale: anchorScale,
                                  scale: anchorScale * ratio, weight: weight, roll: roll)
        pose = locked
        return locked
    }

    mutating func reset() {
        position = nil
        width = 0
        weight = 0
        anchor = .zero
        entry = .zero
        anchorWidth = 0
        anchorScale = 1
        roll = 0
        lostFor = 0
        pose = nil
        centerXSmoother.reset()
        centerYSmoother.reset()
        widthSmoother.reset()
        rollSmoother.reset()
    }

    static func limitedRoll(_ value: CGFloat) -> CGFloat {
        min(max(value, -ZoomTuning.faceLockMaxRoll), ZoomTuning.faceLockMaxRoll)
    }

    static func softenedRatio(_ ratio: CGFloat) -> CGFloat {
        if ratio >= 1 {
            return 1 + softenedChange(ratio - 1, deadZone: ZoomTuning.faceLockFarDeadZone,
                                      ramp: ZoomTuning.faceLockFarRamp)
        }
        return 1 - softenedChange(1 - ratio, deadZone: ZoomTuning.faceLockCloseDeadZone,
                                  ramp: ZoomTuning.faceLockCloseRamp)
    }

    private static func softenedChange(_ change: CGFloat, deadZone: CGFloat, ramp: CGFloat) -> CGFloat {
        guard change > deadZone else { return 0 }
        let over = change - deadZone
        return over < ramp ? over * over / (2 * ramp) : over - ramp / 2
    }

    private mutating func smoothed(_ found: Detection) -> Detection {
        let center = CGPoint(x: centerXSmoother.filter(Double(found.center.x), t: clock),
                             y: centerYSmoother.filter(Double(found.center.y), t: clock))
        let width = CGFloat(widthSmoother.filter(Double(found.width), t: clock))
        let roll = found.roll.map { CGFloat(rollSmoother.filter(Double($0), t: clock)) }
        return Detection(center: center, width: width, roll: roll)
    }

    private static func smoother(_ minCutoff: Double, _ beta: Double) -> OneEuroFilter {
        var filter = OneEuroFilter()
        filter.minCutoff = minCutoff
        filter.beta = beta
        return filter
    }

    private mutating func release(step: TimeInterval) -> FaceLockPose? {
        weight *= CGFloat(exp(-step / ZoomTuning.faceLockReleaseTau))
        guard isEngaged, var fading = pose else {
            reset()
            return nil
        }
        fading.weight = weight
        pose = fading
        return fading
    }
}
