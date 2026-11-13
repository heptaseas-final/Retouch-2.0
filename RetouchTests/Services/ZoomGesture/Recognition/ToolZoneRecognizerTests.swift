import CoreGraphics
import Testing
@testable import Retouch

struct ToolZoneRecognizerTests {
    private let maxSpeed: CGFloat = 1.2

    private func makePoints(nose: CGPoint? = nil) -> FacePoints {
        var points = FacePoints()
        points.leftEye = CGPoint(x: 100, y: 100)
        points.rightEye = CGPoint(x: 200, y: 100)
        points.lips = CGPoint(x: 150, y: 220)
        points.nose = nose
        points.center = CGPoint(x: 150, y: 150)
        points.width = 260
        points.scale = 100
        return points
    }

    private func tool(_ label: ToolDetection.Label, _ rect: CGRect,
                      confidence: Float = 0.8, speed: CGFloat = 0) -> TrackedTool {
        TrackedTool(label: label, confidence: confidence, rect: rect, speed: speed)
    }

    private func read(_ tools: [TrackedTool], nose: CGPoint? = nil, noseActive: Bool = false) -> ToolZoneReading {
        ToolZoneRecognizer(points: makePoints(nose: nose), tools: tools, enterDistance: 0.38,
                           maxIntentSpeed: maxSpeed, noseActive: noseActive, support: false).read()
    }

    private let atLeftEye = CGRect(x: 85, y: 85, width: 30, height: 30)
    private let atLips = CGRect(x: 130, y: 205, width: 40, height: 30)
    private let farAway = CGRect(x: 400, y: 400, width: 30, height: 30)

    @Test func eyeToolAtEyeTriggersEyeOnly() {
        let reading = read([tool(.eye, atLeftEye)])
        #expect(reading.eyeTriggerLeft)
        #expect(!reading.eyeTriggerRight)
        #expect(!reading.lipsTrigger)
        #expect(reading.eyeHoldLeft)
        #expect(reading.isInZone)
    }

    @Test func lipToolAtLipsTriggersLipsOnly() {
        let reading = read([tool(.lip, atLips)])
        #expect(reading.lipsTrigger)
        #expect(reading.lipsHold)
        #expect(!reading.eyeTriggerLeft)
        #expect(!reading.eyeTriggerRight)
    }

    @Test func brushTriggersEyeAndLips() {
        #expect(read([tool(.brush, atLeftEye)]).eyeTriggerLeft)
        #expect(read([tool(.brush, atLips)]).lipsTrigger)
    }

    @Test func eyeToolAtLipsDoesNothing() {
        let reading = read([tool(.eye, atLips)])
        #expect(!reading.lipsTrigger)
        #expect(!reading.lipsHold)
        #expect(!reading.eyeTriggerLeft)
        #expect(!reading.eyeTriggerRight)
        #expect(!reading.isInZone)
    }

    @Test func lipToolAtEyeDoesNothing() {
        let reading = read([tool(.lip, atLeftEye)])
        #expect(!reading.eyeTriggerLeft)
        #expect(!reading.lipsTrigger)
        #expect(!reading.isInZone)
    }

    @Test func lowConfidenceOnlyHolds() {
        let reading = read([tool(.brush, atLeftEye, confidence: 0.4)])
        #expect(!reading.eyeTriggerLeft)
        #expect(reading.eyeHoldLeft)
        #expect(reading.isInZone)
    }

    @Test func confidenceBelowMinimumIsIgnored() {
        let reading = read([tool(.brush, atLeftEye, confidence: 0.3)])
        #expect(reading == ToolZoneReading())
    }

    @Test func fastToolDoesNotTriggerButStillHolds() {
        let reading = read([tool(.brush, atLeftEye, speed: 2)])
        #expect(!reading.eyeTriggerLeft)
        #expect(reading.eyeHoldLeft)
        #expect(reading.isInZone)
    }

    @Test func farToolIsIgnored() {
        #expect(read([tool(.brush, farAway)]) == ToolZoneReading())
    }

    @Test func toolOnNoseDoesNotTriggerEye() {
        let nearNose = CGRect(x: 125, y: 125, width: 30, height: 20)
        #expect(read([tool(.brush, nearNose)]).eyeTriggerLeft)
        #expect(!read([tool(.brush, nearNose)], nose: CGPoint(x: 150, y: 150)).eyeTriggerLeft)
    }
}
