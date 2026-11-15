import CoreGraphics
import Testing
@testable import Retouch

struct ZoomReadinessTests {
    let readiness = ZoomReadiness(hands: [], scan: HandScan(),
                                  converter: CoordinateConverter(imageSize: CGSize(width: 720, height: 1280),
                                                                 viewSize: CGSize(width: 390, height: 844)),
                                  handProfile: HandProfile(), maxIntentSpeed: 1, noseActive: false)

    @Test func noHandsMeansHandLostAndNothingReady() {
        let eye = readiness.eye(points: FacePoints(), support: false)
        let lips = readiness.lips(points: FacePoints(), support: false)
        let nose = readiness.nose(points: FacePoints())
        #expect(eye.handLost && lips.handLost && nose.handLost)
        #expect(!eye.poseLeft && !eye.poseRight && !lips.pose2Ready && !nose.pose2Ready)
    }

    @Test func toolReadingFillsEyeInputTriggerAndHold() {
        var reading = ToolZoneReading()
        reading.eyeTriggerLeft = true
        reading.eyeHoldLeft = true
        reading.eyeHoldRight = true
        let input = ZoomReadiness.applying(reading, to: EyeZoomFlow.Input())
        #expect(input.toolLeft && !input.toolRight)
        #expect(input.holdLeft && input.holdRight)
    }

    @Test func toolReadingKeepsHandHoldOnEyeInput() {
        var base = EyeZoomFlow.Input()
        base.holdRight = true
        let input = ZoomReadiness.applying(ToolZoneReading(), to: base)
        #expect(input.holdRight)
        #expect(!input.toolLeft && !input.toolRight)
    }

    @Test func toolReadingFillsLipsInput() {
        var reading = ToolZoneReading()
        reading.lipsTrigger = true
        reading.lipsHold = true
        let input = ZoomReadiness.applying(reading, to: LipsZoomFlow.Input())
        #expect(input.toolReady && input.fingerNear)
    }

    @Test func toolReadingKeepsHandNearOnLipsInput() {
        var base = LipsZoomFlow.Input()
        base.fingerNear = true
        let input = ZoomReadiness.applying(ToolZoneReading(), to: base)
        #expect(input.fingerNear && !input.toolReady)
    }
}
