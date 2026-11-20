//
//  FaceLayoutGateTests.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 20/11/26.
//


import CoreGraphics
import Foundation
import Testing
@testable import Retouch

struct FaceLayoutGateTests {
    private let start = Date(timeIntervalSinceReferenceDate: 4000)

    private func at(_ seconds: TimeInterval) -> Date { start.addingTimeInterval(seconds) }

    private func face(noseX: CGFloat) -> FacePoints {
        var points = FacePoints()
        points.leftEye = CGPoint(x: 100, y: 100)
        points.rightEye = CGPoint(x: 200, y: 100)
        points.nose = CGPoint(x: noseX, y: 145)
        points.center = CGPoint(x: 150, y: 150)
        points.width = 260
        points.scale = 100
        return points
    }

    private let straight: CGFloat = 150
    private let noseLeft: CGFloat = 120
    private let noseRight: CGFloat = 180

    private func turnedRight() -> FaceLayoutGate {
        var gate = FaceLayoutGate()
        _ = gate.update(points: face(noseX: noseLeft), isFrozen: false, now: at(0))
        _ = gate.update(points: face(noseX: noseLeft), isFrozen: false, now: at(FaceZoneConfig.turnDwell + 0.01))
        return gate
    }

    @Test func staysFrontalWhenNoseIsCentered() {
        var gate = FaceLayoutGate()
        #expect(gate.update(points: face(noseX: straight), isFrozen: false, now: at(0)) == .frontal)
        #expect(gate.update(points: face(noseX: straight), isFrozen: false, now: at(1)) == .frontal)
    }

    @Test func waitsForDwellBeforeTurning() {
        var gate = FaceLayoutGate()
        _ = gate.update(points: face(noseX: noseLeft), isFrozen: false, now: at(0))
        #expect(gate.update(points: face(noseX: noseLeft), isFrozen: false,
                            now: at(FaceZoneConfig.turnDwell - 0.01)) == .frontal)
        #expect(gate.update(points: face(noseX: noseLeft), isFrozen: false,
                            now: at(FaceZoneConfig.turnDwell + 0.01)) == .turned(visibleSide: .right))
    }

    @Test func noseToTheRightShowsTheLeftSide() {
        var gate = FaceLayoutGate()
        _ = gate.update(points: face(noseX: noseRight), isFrozen: false, now: at(0))
        #expect(gate.update(points: face(noseX: noseRight), isFrozen: false,
                            now: at(FaceZoneConfig.turnDwell + 0.01)) == .turned(visibleSide: .left))
    }

    @Test func shortDipWithinGraceKeepsTheTimer() {
        var gate = FaceLayoutGate()
        let dip = min(FaceZoneConfig.turnGrace, FaceZoneConfig.turnDwell) / 2
        _ = gate.update(points: face(noseX: noseLeft), isFrozen: false, now: at(0))
        _ = gate.update(points: face(noseX: straight), isFrozen: false, now: at(dip))
        #expect(gate.update(points: face(noseX: noseLeft), isFrozen: false,
                            now: at(FaceZoneConfig.turnDwell + 0.01)) == .turned(visibleSide: .right))
    }

    @Test func frozenGateKeepsItsLayout() {
        var gate = turnedRight()
        #expect(gate.update(points: face(noseX: straight), isFrozen: true, now: at(2)) == .turned(visibleSide: .right))
        #expect(gate.update(points: face(noseX: straight), isFrozen: true, now: at(3)) == .turned(visibleSide: .right))
    }

    @Test func returnsToFrontalAfterDwell() {
        var gate = turnedRight()
        _ = gate.update(points: face(noseX: straight), isFrozen: false, now: at(2))
        #expect(gate.update(points: face(noseX: straight), isFrozen: false,
                            now: at(2 + FaceZoneConfig.turnDwell + 0.01)) == .frontal)
    }

    @Test func resetGoesBackToFrontal() {
        var gate = turnedRight()
        gate.reset()
        #expect(gate.layout == .frontal)
    }
}