import CoreGraphics
import Testing
@testable import Retouch

struct ZoomReadinessTests {
    let readiness = ZoomReadiness(hands: [], scan: HandScan(),
                                  converter: CoordinateConverter(imageSize: CGSize(width: 720, height: 1280),
                                                                 viewSize: CGSize(width: 390, height: 844)),
                                  handProfile: HandProfile(), maxIntentSpeed: 1, locked: nil)

    @Test func noHandsMeansHandLostAndNothingReady() {
        let eye = readiness.eye(points: FacePoints(), support: false)
        let lips = readiness.lips(points: FacePoints(), support: false)
        let nose = readiness.nose(points: FacePoints(), support: false)
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

    @Test func toolReadingFillsNoseInput() {
        var reading = ToolZoneReading()
        reading.noseTrigger = true
        reading.noseHold = true
        reading.fastTool = true
        let input = ZoomReadiness.applying(reading, to: NoseZoomFlow.Input())
        #expect(input.toolReady && input.fingerNear && input.handMovingAway)
    }

    @Test func toolHoldIsKeptSeparateOnEyeInput() {
        var reading = ToolZoneReading()
        reading.eyeHoldLeft = true
        let input = ZoomReadiness.applying(reading, to: EyeZoomFlow.Input())
        #expect(input.toolHoldLeft && !input.toolHoldRight)
    }

    private func face() -> FacePoints {
        var points = FacePoints()
        points.leftEye = CGPoint(x: 100, y: 100)
        points.rightEye = CGPoint(x: 200, y: 100)
        points.nose = CGPoint(x: 150, y: 145)
        points.lipsTop = CGPoint(x: 150, y: 190)
        points.lips = CGPoint(x: 150, y: 220)
        points.center = CGPoint(x: 150, y: 150)
        points.width = 260
        points.scale = 100
        return points
    }

    private func finger(_ p: CGPoint, id: Int = 1, speed: CGFloat = 0) -> TrackedHand {
        TrackedHand(id: id, point: p, speed: speed, pose2: false, pose3: false, isPoint: true)
    }

    private func ready(_ hands: [TrackedHand], locked: FaceZone? = nil) -> ZoomReadiness {
        var scan = HandScan()
        scan.handsSeen = hands.count
        return ZoomReadiness(hands: hands, scan: scan, converter: readiness.converter,
                             handProfile: HandProfile(), maxIntentSpeed: 1, locked: locked)
    }

    @Test func fingerAtEyeTriggersThatEyeOnly() {
        let r = ready([finger(CGPoint(x: 100, y: 100))])
        let eye = r.eye(points: face(), support: false)
        #expect(eye.pointLeft && !eye.pointRight && eye.holdLeft)
        #expect(!r.lips(points: face(), support: false).pointReady)
        #expect(!r.nose(points: face(), support: false).pointReady)
    }

    @Test func twoFingersUseTheOneNearestFaceCenter() {
        let r = ready([finger(CGPoint(x: 100, y: 100), id: 1), finger(CGPoint(x: 150, y: 200), id: 2)])
        #expect(r.lips(points: face(), support: false).pointReady)
        #expect(!r.eye(points: face(), support: false).pointLeft)
    }

    @Test func fingerInLockedZoneWinsOverNearest() {
        let r = ready([finger(CGPoint(x: 100, y: 100), id: 1), finger(CGPoint(x: 150, y: 200), id: 2)],
                        locked: .leftEye)
        #expect(r.eye(points: face(), support: false).pointLeft)
        #expect(!r.lips(points: face(), support: false).pointReady)
    }

    @Test func fingerOnCheekDoesNothing() {
        let r = ready([finger(CGPoint(x: 210, y: 160))])
        let eye = r.eye(points: face(), support: false)
        #expect(!eye.pointLeft && !eye.pointRight)
        #expect(!r.lips(points: face(), support: false).pointReady)
        #expect(!r.nose(points: face(), support: false).pointReady)
    }

    @Test func fastFingerHoldsButDoesNotTrigger() {
        let r = ready([finger(CGPoint(x: 100, y: 100), speed: 2)])
        let eye = r.eye(points: face(), support: false)
        #expect(!eye.pointLeft)
        #expect(eye.holdLeft)
        #expect(eye.handMovingAway)
    }
}
