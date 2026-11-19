//
//  ToolTipLocatorTests.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 19/11/26.
//


import CoreGraphics
import Testing
@testable import Retouch

struct ToolTipLocatorTests {
    private let vertical = CGRect(x: 0, y: 0, width: 20, height: 100)

    @Test func tipSitsAtTheEndFacingTheFace() {
        #expect(ToolTipLocator.tip(of: vertical, toward: CGPoint(x: 10, y: -50)) == CGPoint(x: 10, y: 10))
        #expect(ToolTipLocator.tip(of: vertical, toward: CGPoint(x: 10, y: 200)) == CGPoint(x: 10, y: 90))
    }

    @Test func horizontalToolUsesItsSideEnd() {
        let horizontal = CGRect(x: 0, y: 0, width: 100, height: 20)
        #expect(ToolTipLocator.tip(of: horizontal, toward: CGPoint(x: -50, y: 10)) == CGPoint(x: 10, y: 10))
    }

    @Test func squareToolUsesItsCenter() {
        let square = CGRect(x: 0, y: 0, width: 40, height: 40)
        #expect(ToolTipLocator.tip(of: square, toward: CGPoint(x: 300, y: -300)) == CGPoint(x: 20, y: 20))
    }

    @Test func anchorInsideToolStaysOnItsAxis() {
        #expect(ToolTipLocator.tip(of: vertical, toward: CGPoint(x: 4, y: 40)) == CGPoint(x: 10, y: 40))
    }

    @Test func faceWithoutCenterFallsBackToEyes() {
        var face = FacePoints()
        face.leftEye = CGPoint(x: 0, y: -100)
        face.rightEye = CGPoint(x: 20, y: -100)
        #expect(ToolTipLocator.tip(of: vertical, face: face) == CGPoint(x: 10, y: 10))
    }
}