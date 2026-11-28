//
//  FaceLockDetectorChooseTests.swift
//  Retouch
//
//  Created by Davin P on 28/11/26.
//

import CoreGraphics
import Testing
@testable import Retouch

struct FaceLockDetectorChooseTests {
    private let target = FaceLockFilter.Detection(center: CGPoint(x: 0.3, y: 0.5), width: 0.2)

    @Test func picksTheLargestFaceWhenNothingIsLocked() {
        let small = face(x: 0.3, width: 0.2)
        let large = face(x: 0.7, width: 0.4)
        #expect(FaceLockDetector.choose([small, large], following: nil) == large)
    }

    @Test func keepsTheLockedFaceEvenWhenAnotherFaceIsLarger() {
        let locked = face(x: 0.31, width: 0.2)
        let larger = face(x: 0.7, width: 0.4)
        #expect(FaceLockDetector.choose([larger, locked], following: target) == locked)
    }

    @Test func picksTheNearestFaceWhenTwoAreInReach() {
        let near = face(x: 0.28, width: 0.2)
        let farther = face(x: 0.36, width: 0.2)
        #expect(FaceLockDetector.choose([farther, near], following: target) == near)
    }

    @Test func returnsNilWhenTheLockedFaceLeavesAndOthersRemain() {
        let other = face(x: 0.7, width: 0.4)
        #expect(FaceLockDetector.choose([other], following: target) == nil)
    }

    @Test func returnsNilWhenThereAreNoFaces() {
        #expect(FaceLockDetector.choose([], following: nil) == nil)
        #expect(FaceLockDetector.choose([], following: target) == nil)
    }

    private func face(x: CGFloat, width: CGFloat) -> FaceLockFilter.Detection {
        FaceLockFilter.Detection(center: CGPoint(x: x, y: 0.5), width: width)
    }
}
