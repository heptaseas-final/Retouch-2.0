import CoreGraphics
import Testing
@testable import Retouch

struct ZoomReadinessTests {
    let readiness = ZoomReadiness(hands: [], scan: HandScan(),
                                  converter: CoordinateConverter(imageSize: CGSize(width: 720, height: 1280),
                                                                 viewSize: CGSize(width: 390, height: 844)),
                                  maxIntentSpeed: 1, locked: nil)

    private let flatConverter = CoordinateConverter(imageSize: CGSize(width: 390, height: 844),
                                                    viewSize: CGSize(width: 390, height: 844))

    @Test func noHandsMeansHandLostAndNothingReady() {
        let eye = readiness.eye(points: FacePoints(), support: false)
        let lips = readiness.lips(points: FacePoints())
        let nose = readiness.nose(points: FacePoints())
        let cheek = readiness.cheek(points: FacePoints())
        #expect(eye.handLost && lips.handLost && nose.handLost)
        #expect(!eye.poseLeft && !eye.poseRight && !lips.pose2Ready && !nose.pose2Ready)
        #expect(!cheek.readyLeft && !cheek.readyRight)
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

    @Test func toolReadingFillsCheekInput() {
        var reading = ToolZoneReading()
        reading.cheekTriggerRight = true
        reading.cheekHoldRight = true
        reading.fastTool = true
        let input = ZoomReadiness.applying(reading, to: CheekZoomFlow.Input())
        #expect(input.readyRight && input.nearRight && input.handMovingAway)
        #expect(!input.readyLeft && !input.nearLeft)
    }

    @Test func toolHoldIsKeptSeparateOnEyeInput() {
        var reading = ToolZoneReading()
        reading.eyeHoldLeft = true
        let input = ZoomReadiness.applying(reading, to: EyeZoomFlow.Input())
        #expect(input.toolHoldLeft && !input.toolHoldRight)
    }

    private func face(layout: FaceZoneLayout = .frontal) -> FacePoints {
        var points = FacePoints()
        points.leftEye = CGPoint(x: 100, y: 100)
        points.rightEye = CGPoint(x: 200, y: 100)
        points.nose = layout == .frontal ? CGPoint(x: 150, y: 145) : CGPoint(x: 120, y: 145)
        points.lipsTop = CGPoint(x: 150, y: 190)
        points.lips = CGPoint(x: 150, y: 220)
        points.center = CGPoint(x: 150, y: 150)
        points.width = 260
        points.scale = 100
        points.layout = layout
        return points
    }

    private func finger(_ p: CGPoint, id: Int = 1, speed: CGFloat = 0) -> TrackedHand {
        TrackedHand(id: id, point: p, speed: speed, pose2: false, pose3: false, isPoint: true)
    }

    private func ready(_ hands: [TrackedHand], locked: FaceZone? = nil,
                       fingertips: [CGPoint] = []) -> ZoomReadiness {
        var scan = HandScan()
        scan.handsSeen = hands.count
        scan.fingertips = fingertips.map { CGPoint(x: $0.x / 390, y: 1 - $0.y / 844) }
        return ZoomReadiness(hands: hands, scan: scan, converter: flatConverter,
                             maxIntentSpeed: 1, locked: locked)
    }

    @Test func fingerAtEyeTriggersThatEyeOnly() {
        let r = ready([finger(CGPoint(x: 100, y: 100))])
        let eye = r.eye(points: face(), support: false)
        #expect(eye.pointLeft && !eye.pointRight && eye.holdLeft)
        #expect(!r.lips(points: face()).pointReady)
        #expect(!r.nose(points: face()).pointReady)
    }

    @Test func twoFingersUseTheOneNearestFaceCenter() {
        let r = ready([finger(CGPoint(x: 100, y: 100), id: 1), finger(CGPoint(x: 150, y: 200), id: 2)])
        #expect(r.lips(points: face()).pointReady)
        #expect(!r.eye(points: face(), support: false).pointLeft)
    }

    @Test func fingerInLockedZoneWinsOverNearest() {
        let r = ready([finger(CGPoint(x: 100, y: 100), id: 1), finger(CGPoint(x: 150, y: 200), id: 2)],
                      locked: .leftEye)
        #expect(r.eye(points: face(), support: false).pointLeft)
        #expect(!r.lips(points: face()).pointReady)
    }

    @Test func fingerOnCheekDoesNothingWhenFrontal() {
        let r = ready([finger(CGPoint(x: 210, y: 160))])
        let eye = r.eye(points: face(), support: false)
        #expect(!eye.pointLeft && !eye.pointRight)
        #expect(!r.lips(points: face()).pointReady)
        #expect(!r.nose(points: face()).pointReady)
        #expect(!r.cheek(points: face()).readyRight)
    }

    @Test func fingerOnCheekTriggersCheekWhenTurned() {
        let turned = face(layout: .turned(visibleSide: .right))
        let r = ready([finger(CGPoint(x: 240, y: 175))])
        let cheek = r.cheek(points: turned)
        #expect(cheek.readyRight && cheek.nearRight)
        #expect(!cheek.readyLeft)
        #expect(!r.eye(points: turned, support: false).pointRight)
    }

    @Test func fingertipOnEyeBeatsHandPointOnCheek() {
        let turned = face(layout: .turned(visibleSide: .right))
        let r = ready([finger(CGPoint(x: 240, y: 175))], fingertips: [CGPoint(x: 200, y: 130)])
        let eye = r.eye(points: turned, support: false)
        #expect(eye.pointRight && eye.holdRight)
        #expect(!r.cheek(points: turned).readyRight)
    }

    @Test func fastFingerHoldsButDoesNotTrigger() {
        let r = ready([finger(CGPoint(x: 100, y: 100), speed: 2)])
        let eye = r.eye(points: face(), support: false)
        #expect(!eye.pointLeft)
        #expect(eye.holdLeft)
        #expect(eye.handMovingAway)
    }
}
