//
//  FaceZoneMapTests.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 19/11/26.
//


import CoreGraphics
import Testing
@testable import Retouch

struct FaceZoneMapTests {
    private func makeMap(lips: Bool = true) -> FaceZoneMap? {
        var points = FacePoints()
        points.leftEye = CGPoint(x: 100, y: 100)
        points.rightEye = CGPoint(x: 200, y: 100)
        points.nose = CGPoint(x: 150, y: 145)
        if lips {
            points.lips = CGPoint(x: 150, y: 220)
            points.lipsTop = CGPoint(x: 150, y: 190)
        }
        points.center = CGPoint(x: 150, y: 150)
        points.width = 260
        points.scale = 100
        return FaceZoneMap(points: points)
    }

    @Test func landmarksLandInTheirOwnZone() throws {
        let map = try #require(makeMap())
        #expect(map.zone(of: CGPoint(x: 100, y: 100)) == .leftEye)
        #expect(map.zone(of: CGPoint(x: 200, y: 100)) == .rightEye)
        #expect(map.zone(of: CGPoint(x: 150, y: 145)) == .nose)
        #expect(map.zone(of: CGPoint(x: 150, y: 220)) == .lips)
    }

    @Test func innerEyeCornerIsEye() throws {
        let map = try #require(makeMap())
        #expect(map.zone(of: CGPoint(x: 130, y: 115)) == .leftEye)
    }

    @Test func cheekForeheadAndChinAreNoZone() throws {
        let map = try #require(makeMap())
        #expect(map.zone(of: CGPoint(x: 210, y: 160)) == nil)
        #expect(map.zone(of: CGPoint(x: 150, y: 30)) == nil)
        #expect(map.zone(of: CGPoint(x: 150, y: 320)) == nil)
    }

    @Test func noseAndLipsSplitHalfwayBetweenNoseAndUpperLip() throws {
        let map = try #require(makeMap())
        #expect(map.zone(of: CGPoint(x: 150, y: 165)) == .nose)
        #expect(map.zone(of: CGPoint(x: 150, y: 170)) == .lips)
    }

    @Test func lockedLipsReachesSlightlyAboveTheLine() throws {
        let map = try #require(makeMap())
        let p = CGPoint(x: 150, y: 160)
        #expect(map.zone(of: p) == .nose)
        #expect(map.zone(of: p, locked: .lips) == .lips)
        #expect(map.holds(.lips, at: p))
    }

    @Test func lockedNoseReachesSlightlyBelowTheLine() throws {
        let map = try #require(makeMap())
        let p = CGPoint(x: 150, y: 175)
        #expect(map.zone(of: p) == .lips)
        #expect(map.zone(of: p, locked: .nose) == .nose)
    }

    @Test func lockDoesNotSwallowTheNextZone() throws {
        let map = try #require(makeMap())
        #expect(map.zone(of: CGPoint(x: 150, y: 135), locked: .lips) == .nose)
        #expect(map.zone(of: CGPoint(x: 150, y: 220), locked: .nose) == .lips)
        #expect(map.zone(of: CGPoint(x: 200, y: 100), locked: .leftEye) == .rightEye)
    }

    @Test func everyPointHasAtMostOneOwner() throws {
        let map = try #require(makeMap())
        for x in stride(from: 40.0, through: 260.0, by: 4.0) {
            for y in stride(from: 40.0, through: 300.0, by: 4.0) {
                let p = CGPoint(x: x, y: y)
                let owners = FaceZone.allCases.filter { map.zone(of: p) == $0 }
                #expect(owners.count <= 1)
                if let zone = map.zone(of: p) {
                    #expect(map.holds(zone, at: p))
                }
            }
        }
    }

    @Test func withoutLipsOnlyEyesRemain() throws {
        let map = try #require(makeMap(lips: false))
        #expect(map.zone(of: CGPoint(x: 100, y: 100)) == .leftEye)
        #expect(map.zone(of: CGPoint(x: 150, y: 145)) == nil)
        #expect(map.zone(of: CGPoint(x: 150, y: 220)) == nil)
    }
}