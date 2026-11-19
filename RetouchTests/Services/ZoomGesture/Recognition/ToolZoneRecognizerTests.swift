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

    private let nose = CGPoint(x: 150, y: 145)
    private let onNose = CGRect(x: 142, y: 137, width: 16, height: 16)
    private let onBridgeCorner = CGRect(x: 120, y: 115, width: 20, height: 20)

    @Test func brushOnNoseTriggersNoseOnly() {
        let reading = read([tool(.brush, onNose)], nose: nose)
        #expect(reading.noseTrigger)
        #expect(reading.noseHold)
        #expect(!reading.eyeTriggerLeft)
        #expect(!reading.eyeTriggerRight)
        #expect(reading.isInZone)
    }

    @Test func eyeAndLipToolsNeverTriggerNose() {
        for label in [ToolDetection.Label.eye, .lip] {
            let reading = read([tool(label, onNose)], nose: nose)
            #expect(!reading.noseTrigger)
            #expect(!reading.noseHold)
            #expect(!reading.eyeTriggerLeft)
            #expect(!reading.eyeTriggerRight)
        }
    }

    @Test func brushAtInnerEyeCornerBelongsToEye() {
        let reading = read([tool(.brush, onBridgeCorner)], nose: nose)
        #expect(reading.eyeTriggerLeft)
        #expect(!reading.noseTrigger)
    }

    @Test func largeBrushPicksEyeItMostlyCovers() {
        let mostlyRight = CGRect(x: 130, y: 80, width: 100, height: 40)
        let reading = read([tool(.brush, mostlyRight)], nose: nose)
        #expect(reading.eyeTriggerRight)
        #expect(!reading.eyeTriggerLeft)
    }

    @Test func fastToolIsReported() {
        #expect(read([tool(.brush, atLeftEye, speed: 2)]).fastTool)
        #expect(!read([tool(.brush, atLeftEye)]).fastTool)
    }
}
