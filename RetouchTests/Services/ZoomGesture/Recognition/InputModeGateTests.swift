//
//  InputModeGateTests.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 19/11/26.
//


import CoreGraphics
import Foundation
import Testing
@testable import Retouch

struct InputModeGateTests {
    private let start = Date(timeIntervalSinceReferenceDate: 4000)

    private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    private func toolMode() -> InputModeGate {
        var gate = InputModeGate()
        gate.note(.strong, at: at(0))
        gate.note(.strong, at: at(0.1))
        gate.update(zoomActive: false, now: at(0.1))
        return gate
    }

    @Test func startsInFingerMode() {
        #expect(InputModeGate().mode == .finger)
    }

    @Test func oneDetectionIsNotEnough() {
        var gate = InputModeGate()
        gate.note(.strong, at: at(0))
        #expect(gate.update(zoomActive: false, now: at(0)) == .finger)
    }

    @Test func twoDetectionsInARowEnterToolMode() {
        #expect(toolMode().mode == .tool)
    }

    @Test func missedDetectionBreaksTheStreak() {
        var gate = InputModeGate()
        gate.note(.strong, at: at(0))
        gate.note(.none, at: at(0.1))
        gate.note(.strong, at: at(0.2))
        #expect(gate.update(zoomActive: false, now: at(0.2)) == .finger)
    }

    @Test func weakDetectionDoesNotEnterToolMode() {
        var gate = InputModeGate()
        gate.note(.weak, at: at(0))
        gate.note(.weak, at: at(0.1))
        #expect(gate.update(zoomActive: false, now: at(0.1)) == .finger)
    }

    @Test func toolModeHoldsUntilToolGoneLongEnough() {
        var gate = toolMode()
        gate.note(.none, at: at(0.5))
        #expect(gate.update(zoomActive: false, now: at(0.1 + ToolDetectionTuning.toolModeExitAfter - 0.05)) == .tool)
        #expect(gate.update(zoomActive: false, now: at(0.1 + ToolDetectionTuning.toolModeExitAfter + 0.05)) == .finger)
    }

    @Test func weakDetectionKeepsToolMode() {
        var gate = toolMode()
        gate.note(.weak, at: at(1.2))
        #expect(gate.update(zoomActive: false, now: at(2.0)) == .tool)
    }

    @Test func activeZoomLocksFingerMode() {
        var gate = InputModeGate()
        gate.note(.strong, at: at(0))
        gate.note(.strong, at: at(0.1))
        #expect(gate.update(zoomActive: true, now: at(0.1)) == .finger)
        #expect(gate.update(zoomActive: false, now: at(0.3)) == .tool)
    }

    @Test func activeZoomLocksToolMode() {
        var gate = toolMode()
        #expect(gate.update(zoomActive: true, now: at(5)) == .tool)
        #expect(gate.update(zoomActive: false, now: at(5)) == .finger)
    }

    @Test func staleStreakDoesNotEnterToolModeLater() {
        var gate = InputModeGate()
        gate.note(.strong, at: at(0))
        gate.note(.strong, at: at(0.1))
        gate.update(zoomActive: true, now: at(0.1))
        #expect(gate.update(zoomActive: false, now: at(0.1 + ToolDetectionTuning.toolModeExitAfter + 0.1)) == .finger)
    }

    @Test func resetReturnsToFingerMode() {
        var gate = toolMode()
        gate.reset()
        #expect(gate.mode == .finger)
    }

    private func face() -> FacePoints {
        var points = FacePoints()
        points.leftEye = CGPoint(x: 100, y: 100)
        points.rightEye = CGPoint(x: 200, y: 100)
        points.center = CGPoint(x: 150, y: 150)
        points.width = 260
        points.scale = 100
        return points
    }

    private func tool(_ rect: CGRect, confidence: Float) -> TrackedTool {
        TrackedTool(label: .brush, confidence: confidence, rect: rect, speed: 0)
    }

    @Test func presenceNeedsToolOnTheFace() {
        let onFace = CGRect(x: 90, y: 90, width: 20, height: 20)
        let farAway = CGRect(x: 800, y: 800, width: 20, height: 20)
        #expect(InputModeGate.presence(of: [tool(onFace, confidence: 0.8)], face: face()) == .strong)
        #expect(InputModeGate.presence(of: [tool(onFace, confidence: 0.4)], face: face()) == .weak)
        #expect(InputModeGate.presence(of: [tool(onFace, confidence: 0.2)], face: face()) == .none)
        #expect(InputModeGate.presence(of: [tool(farAway, confidence: 0.9)], face: face()) == .none)
        #expect(InputModeGate.presence(of: [], face: face()) == .none)
    }
}