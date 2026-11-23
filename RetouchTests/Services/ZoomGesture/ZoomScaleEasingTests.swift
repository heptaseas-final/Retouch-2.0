//
//  ZoomScaleEasingTests.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 20/11/26.
//


import CoreGraphics
import Foundation
import Testing
@testable import Retouch

struct ZoomScaleEasingTests {
    private let frame: CGFloat = 1.0 / 60
    private let start = ZoomTuning.fullFaceZoom
    private let overall: CGFloat = 0.615

    @Test func enteringOverallEases() {
        #expect(ZoomScaleEasing.easesAfterGoal(wasEasing: false, wasOverall: false, isOverall: true, modeChanged: true))
    }

    @Test func leavingOverallEases() {
        #expect(ZoomScaleEasing.easesAfterGoal(wasEasing: false, wasOverall: true, isOverall: false, modeChanged: true))
    }

    @Test func repeatedOverallGoalKeepsEasing() {
        #expect(ZoomScaleEasing.easesAfterGoal(wasEasing: true, wasOverall: true, isOverall: true, modeChanged: false))
    }

    @Test func eyeOrLipZoomKeepsTheOldCurve() {
        #expect(!ZoomScaleEasing.easesAfterGoal(wasEasing: true, wasOverall: false, isOverall: false, modeChanged: true))
        #expect(!ZoomScaleEasing.easesAfterGoal(wasEasing: false, wasOverall: false, isOverall: false, modeChanged: false))
    }

    @Test func easedZoomStartsGently() {
        var velocity: CGFloat = 0
        let next = ZoomScaleEasing.easedStep(current: start, goal: overall, velocity: &velocity,
                                             smoothTime: ZoomTuning.overallScaleSmoothTime, dt: frame)
        let oldCurveStep = (start - overall) * (1 - exp(-frame / ZoomTuning.zoomOutTau))
        #expect(start - next < oldCurveStep)
    }

    @Test func easedZoomArrivesInAboutThreeSmoothTimes() {
        var current = start
        var velocity: CGFloat = 0
        let frames = Int((3 * ZoomTuning.overallScaleSmoothTime / frame).rounded(.up))
        for _ in 0..<frames {
            current = ZoomScaleEasing.easedStep(current: current, goal: overall, velocity: &velocity,
                                                smoothTime: ZoomTuning.overallScaleSmoothTime, dt: frame)
        }
        #expect(abs(current - overall) < 0.05 * (start - overall))
    }

    @Test func easedZoomNeverOvershoots() {
        var current = start
        var velocity: CGFloat = 0
        for _ in 0..<240 {
            current = ZoomScaleEasing.easedStep(current: current, goal: overall, velocity: &velocity,
                                                smoothTime: ZoomTuning.overallScaleSmoothTime, dt: frame)
            #expect(current >= overall - 0.000_1)
        }
        #expect(ZoomScaleEasing.isSettled(current: current, goal: overall, velocity: velocity))
    }
}
