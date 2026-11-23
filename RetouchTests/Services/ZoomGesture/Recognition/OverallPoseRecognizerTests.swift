import CoreGraphics
import Foundation
import Testing
@testable import Retouch

struct OverallPoseRecognizerTests {
    private func face(width: CGFloat, yaw: Double = 0) -> FaceObservation {
        FaceObservation(center: CGPoint(x: 0.5, y: 0.5), width: width, yaw: yaw, aspect: 1)
    }

    private func motion(tilt: Double = 0, stillFor: TimeInterval = 0,
                        movingFor: TimeInterval = 0) -> DeviceMotionSample {
        DeviceMotionSample(tiltDown: tilt, stillFor: stillFor, movingFor: movingFor)
    }

    private let still = 2.0

    @Test func placedPhoneWithSmallFaceEntersPlaced() {
        var recognizer = OverallPoseRecognizer()
        let pose = recognizer.update(face: face(width: 0.17), motion: motion(stillFor: still), now: 0)
        #expect(pose == .placedFar)
    }

    @Test func placedNeedsPhoneStillLongEnough() {
        var recognizer = OverallPoseRecognizer()
        let pose = recognizer.update(face: face(width: 0.1),
                                     motion: motion(stillFor: ZoomTuning.placedStillDwell - 0.1), now: 0)
        #expect(pose == .none)
    }

    @Test func placedNeedsFaceFarEnough() {
        var recognizer = OverallPoseRecognizer()
        let tooClose = face(width: CGFloat(ZoomTuning.placedEnterWidth + 0.01))
        #expect(recognizer.update(face: tooClose, motion: motion(stillFor: still), now: 0) == .none)
    }

    @Test func placedHoldsUntilExitWidth() {
        var recognizer = OverallPoseRecognizer()
        _ = recognizer.update(face: face(width: 0.1), motion: motion(stillFor: still), now: 0)
        let holding = face(width: CGFloat((ZoomTuning.placedEnterWidth + ZoomTuning.placedExitWidth) / 2))
        let leaving = face(width: CGFloat(ZoomTuning.placedExitWidth + 0.01))
        #expect(recognizer.update(face: holding, motion: motion(stillFor: still), now: 1) == .placedFar)
        #expect(recognizer.update(face: leaving, motion: motion(stillFor: still), now: 2) == .none)
    }

    @Test func lostFaceKeepsPlaced() {
        var recognizer = OverallPoseRecognizer()
        _ = recognizer.update(face: face(width: 0.1), motion: motion(stillFor: still), now: 0)
        #expect(recognizer.update(face: nil, motion: motion(stillFor: still), now: 3) == .placedFar)
    }

    @Test func pickingUpPhoneLeavesPlaced() {
        var recognizer = OverallPoseRecognizer()
        _ = recognizer.update(face: face(width: 0.1), motion: motion(stillFor: still), now: 0)
        #expect(recognizer.update(face: nil, motion: motion(movingFor: 0.1), now: 1) == .placedFar)
        let pose = recognizer.update(face: nil, motion: motion(movingFor: ZoomTuning.placedMoveGrace + 0.05), now: 2)
        #expect(pose == .none)
    }

    @Test func heldHighEntersAfterDwell() {
        var recognizer = OverallPoseRecognizer()
        let high = face(width: 0.4)
        #expect(recognizer.update(face: high, motion: motion(tilt: 18), now: 0) == .none)
        #expect(recognizer.update(face: high, motion: motion(tilt: 18),
                                  now: ZoomTuning.highEnterDwell - 0.05) == .none)
        #expect(recognizer.update(face: high, motion: motion(tilt: 18),
                                  now: ZoomTuning.highEnterDwell + 0.05) == .heldHigh)
    }

    @Test func heldHighNeedsTiltDownAndSmallFace() {
        var upright = OverallPoseRecognizer()
        _ = upright.update(face: face(width: 0.35), motion: motion(tilt: 10), now: 0)
        #expect(upright.update(face: face(width: 0.35), motion: motion(tilt: 10), now: 1) == .none)

        var tiltedUp = OverallPoseRecognizer()
        _ = tiltedUp.update(face: face(width: 0.35), motion: motion(tilt: -40), now: 0)
        #expect(tiltedUp.update(face: face(width: 0.35), motion: motion(tilt: -40), now: 1) == .none)

        var flatAbove = OverallPoseRecognizer()
        _ = flatAbove.update(face: face(width: 0.35), motion: motion(tilt: 85), now: 0)
        #expect(flatAbove.update(face: face(width: 0.35), motion: motion(tilt: 85), now: 1) == .none)

        var tooClose = OverallPoseRecognizer()
        _ = tooClose.update(face: face(width: 0.5), motion: motion(tilt: 45), now: 0)
        #expect(tooClose.update(face: face(width: 0.5), motion: motion(tilt: 45), now: 1) == .none)
    }

    @Test func heldHighHoldsUntilExitWidth() {
        var recognizer = OverallPoseRecognizer()
        _ = recognizer.update(face: face(width: 0.4), motion: motion(tilt: 30), now: 0)
        _ = recognizer.update(face: face(width: 0.4), motion: motion(tilt: 30), now: 1)
        #expect(recognizer.update(face: face(width: 0.52), motion: motion(tilt: 30), now: 2) == .heldHigh)
        #expect(recognizer.update(face: face(width: 0.58), motion: motion(tilt: 30), now: 3) == .none)
    }

    @Test func loweringPhoneLeavesHeldHigh() {
        var recognizer = OverallPoseRecognizer()
        let high = face(width: 0.35)
        _ = recognizer.update(face: high, motion: motion(tilt: 30), now: 0)
        _ = recognizer.update(face: high, motion: motion(tilt: 30), now: 1)
        #expect(recognizer.update(face: high, motion: motion(tilt: 10), now: 2) == .heldHigh)
        #expect(recognizer.update(face: high, motion: motion(tilt: 6), now: 3) == .none)
    }

    @Test func noMotionDataMeansNoOverall() {
        var recognizer = OverallPoseRecognizer()
        #expect(recognizer.update(face: face(width: 0.1), motion: nil, now: 0) == .none)
    }
}
