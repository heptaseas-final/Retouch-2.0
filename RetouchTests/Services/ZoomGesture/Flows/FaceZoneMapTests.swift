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
    private func makePoints(lips: Bool = true, nose: CGPoint = CGPoint(x: 150, y: 145),
                            layout: FaceZoneLayout = .frontal) -> FacePoints {
        var points = FacePoints()
        points.leftEye = CGPoint(x: 100, y: 100)
        points.rightEye = CGPoint(x: 200, y: 100)
        points.nose = nose
        if lips {
            points.lips = CGPoint(x: 150, y: 220)
            points.lipsTop = CGPoint(x: 150, y: 190)
        }
        points.center = CGPoint(x: 150, y: 150)
        points.width = 260
        points.scale = 100
        points.layout = layout
        return points
    }

    private func makeMap(lips: Bool = true) -> FaceZoneMap? {
        FaceZoneMap(points: makePoints(lips: lips))
    }

    private func makeTurnedMap() -> FaceZoneMap? {
        FaceZoneMap(points: makePoints(nose: CGPoint(x: 120, y: 145), layout: .turned(visibleSide: .right)))
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
        #expect(map.zone(of: CGPoint(x: 122, y: 100)) == .leftEye)
    }

    @Test func underEyeIsEye() throws {
        let map = try #require(makeMap())
        #expect(map.zone(of: CGPoint(x: 100, y: 140)) == .leftEye)
    }

    @Test func areaBesideNoseBridgeIsNose() throws {
        let map = try #require(makeMap())
        #expect(map.zone(of: CGPoint(x: 130, y: 115)) == .nose)
    }

    @Test func cheekForeheadAndChinAreNoZoneWhenFrontal() throws {
        let map = try #require(makeMap())
        #expect(map.zone(of: CGPoint(x: 210, y: 160)) == nil)
        #expect(map.zone(of: CGPoint(x: 150, y: 30)) == nil)
        #expect(map.zone(of: CGPoint(x: 150, y: 320)) == nil)
    }

    @Test func noseAndLipsMeetBelowTheNose() throws {
        let map = try #require(makeMap())
        #expect(map.zone(of: CGPoint(x: 150, y: 170)) == .nose)
        #expect(map.zone(of: CGPoint(x: 150, y: 185)) == .lips)
    }

    @Test func lockedLipsReachesAboveTheBoundary() throws {
        let map = try #require(makeMap())
        let p = CGPoint(x: 150, y: 174)
        #expect(map.zone(of: p) == .nose)
        #expect(map.zone(of: p, locked: .lips) == .lips)
        #expect(map.holds(.lips, at: p))
    }

    @Test func lockedNoseReachesBelowTheBoundary() throws {
        let map = try #require(makeMap())
        let p = CGPoint(x: 150, y: 182)
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

    @Test func missingLipsTopFallsBackToDefaultDepth() throws {
        let map = try #require(makeMap(lips: false))
        #expect(map.zone(of: CGPoint(x: 100, y: 100)) == .leftEye)
        #expect(map.zone(of: CGPoint(x: 150, y: 145)) == .nose)
        #expect(map.zone(of: CGPoint(x: 150, y: 220)) == .lips)
    }

    @Test func noMapWithoutBothEyes() {
        var points = makePoints()
        points.rightEye = nil
        #expect(FaceZoneMap(points: points) == nil)
    }

    @Test func turnedFaceKeepsOnlyNearEyeNoseAndCheek() throws {
        let map = try #require(makeTurnedMap())
        #expect(map.zone(of: CGPoint(x: 200, y: 100)) == .rightEye)
        #expect(map.zone(of: CGPoint(x: 200, y: 135)) == .rightEye)
        #expect(map.zone(of: CGPoint(x: 160, y: 120)) == .nose)
        #expect(map.zone(of: CGPoint(x: 240, y: 175)) == .rightCheek)
        #expect(map.zone(of: CGPoint(x: 100, y: 100)) == nil)
        #expect(map.zone(of: CGPoint(x: 150, y: 220)) == nil)
    }

    @Test func primaryPointInEyeBeatsLockedCheek() throws {
        let map = try #require(makeTurnedMap())
        let zone = map.zone(primary: CGPoint(x: 200, y: 135), others: [CGPoint(x: 240, y: 175)], locked: .rightCheek)
        #expect(zone == .rightEye)
    }

    @Test func lockedCheekIgnoresAStrayFingertipOnTheEye() throws {
        let map = try #require(makeTurnedMap())
        let zone = map.zone(primary: CGPoint(x: 240, y: 175), others: [CGPoint(x: 200, y: 100)], locked: .rightCheek)
        #expect(zone == .rightCheek)
    }

    @Test func lockedEyeHoldsWhenHandPointJumpsToCheek() throws {
        let map = try #require(makeTurnedMap())
        let zone = map.zone(primary: CGPoint(x: 240, y: 175), others: [CGPoint(x: 200, y: 110)], locked: .rightEye)
        #expect(zone == .rightEye)
    }

    @Test func withoutLockTheMostSpecificZoneWins() throws {
        let map = try #require(makeTurnedMap())
        let zone = map.zone(primary: CGPoint(x: 240, y: 175), others: [CGPoint(x: 200, y: 130)])
        #expect(zone == .rightEye)
    }
}
