//
//  FaceZoneShapeTests.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 20/11/26.
//


import CoreGraphics
import Testing
@testable import Retouch

struct FaceZoneShapeTests {
    private let square = FaceZoneShape(vertices: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 0),
                                                  CGPoint(x: 100, y: 100), CGPoint(x: 0, y: 100)])

    @Test func containsPointsInside() {
        #expect(square.contains(CGPoint(x: 50, y: 50)))
        #expect(square.contains(CGPoint(x: 5, y: 95)))
    }

    @Test func rejectsPointsOutside() {
        #expect(!square.contains(CGPoint(x: 105, y: 50)))
        #expect(!square.contains(CGPoint(x: 50, y: -5)))
    }

    @Test func growingReachesJustOutside() {
        let p = CGPoint(x: 105, y: 50)
        #expect(!square.contains(p))
        #expect(square.contains(p, grownBy: 1.2))
        #expect(!square.contains(CGPoint(x: 115, y: 50), grownBy: 1.2))
    }

    @Test func tooFewVerticesContainNothing() {
        let line = FaceZoneShape(vertices: [CGPoint(x: 0, y: 0), CGPoint(x: 100, y: 100)])
        #expect(!line.contains(CGPoint(x: 50, y: 50)))
    }
}