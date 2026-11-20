import CoreGraphics
import Testing
@testable import Retouch

struct ToolZoneRecognizerTests {
    private let maxSpeed: CGFloat = 1.2

    private func makePoints(nose: CGPoint? = CGPoint(x: 150, y: 145)) -> FacePoints {
        var points = FacePoints()
        points.leftEye = CGPoint(x: 100, y: 100)
        points.rightEye = CGPoint(x: 200, y: 100)
        points.lips = CGPoint(x: 150, y: 220)
        points.lipsTop = CGPoint(x: 150, y: 190)
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

    private func read(_ tools: [TrackedTool], locked: FaceZone? = nil) -> ToolZoneReading {
        ToolZoneRecognizer(points: makePoints(), tools: tools, enterDistance: 0.38,
                           maxIntentSpeed: maxSpeed, locked: locked, support: false).read()
    }

    private let atLeftEye = CGRect(x: 85, y: 85, width: 30, height: 30)
    private let atLips = CGRect(x: 130, y: 205, width: 40, height: 30)
    private let onNose = CGRect(x: 142, y: 137, width: 16, height: 16)
    private let farAway = CGRect(x: 400, y: 400, width: 30, height: 30)

    @Test func eyeToolAtEyeTriggersEyeOnly() {
        let reading = read([tool(.eye, atLeftEye)])
        #expect(reading.eyeTriggerLeft)
        #expect(!reading.eyeTriggerRight && !reading.lipsTrigger && !reading.noseTrigger)
        #expect(reading.eyeHoldLeft)
        #expect(reading.isInZone)
    }

    @Test func lipToolAtLipsTriggersLipsOnly() {
        let reading = read([tool(.lip, atLips)])
        #expect(reading.lipsTrigger && reading.lipsHold)
        #expect(!reading.eyeTriggerLeft && !reading.eyeTriggerRight && !reading.noseTrigger)
    }

    @Test func brushReachesEveryZone() {
        #expect(read([tool(.brush, atLeftEye)]).eyeTriggerLeft)
        #expect(read([tool(.brush, atLips)]).lipsTrigger)
        #expect(read([tool(.brush, onNose)]).noseTrigger)
    }

    @Test func everyToolReachesEveryZone() {
        for label in [ToolDetection.Label.eye, .lip, .brush] {
            #expect(read([tool(label, atLeftEye)]).eyeTriggerLeft)
            #expect(read([tool(label, atLips)]).lipsTrigger)
            #expect(read([tool(label, onNose)]).noseTrigger)
        }
    }

    @Test func lowConfidenceOnlyHolds() {
        let reading = read([tool(.brush, atLeftEye, confidence: 0.6)])
        #expect(!reading.eyeTriggerLeft)
        #expect(reading.eyeHoldLeft)
        #expect(reading.isInZone)
    }

    @Test func confidenceBelowMinimumIsIgnored() {
        #expect(read([tool(.brush, atLeftEye, confidence: 0.3)]) == ToolZoneReading())
    }

    @Test func fastToolDoesNotTriggerButStillHolds() {
        let reading = read([tool(.brush, atLeftEye, speed: 2)])
        #expect(!reading.eyeTriggerLeft)
        #expect(reading.eyeHoldLeft)
        #expect(reading.fastTool)
    }

    @Test func farToolIsIgnored() {
        #expect(read([tool(.brush, farAway)]) == ToolZoneReading())
    }

    @Test func handleOverMouthDoesNotPullNoseBrushToLips() {
        let brushFromBelow = CGRect(x: 140, y: 135, width: 20, height: 140)
        let reading = read([tool(.brush, brushFromBelow)])
        #expect(reading.noseTrigger)
        #expect(!reading.lipsTrigger)
    }

    @Test func lipstickFromBelowUsesItsTip() {
        let lipstick = CGRect(x: 140, y: 200, width: 20, height: 100)
        #expect(read([tool(.lip, lipstick)]).lipsTrigger)
    }

    @Test func brushOnCheekDoesNotZoom() {
        let cheek = CGRect(x: 190, y: 140, width: 60, height: 40)
        let reading = read([tool(.brush, cheek)])
        #expect(!reading.eyeTriggerLeft && !reading.eyeTriggerRight)
        #expect(!reading.noseTrigger && !reading.lipsTrigger)
        #expect(!reading.isInZone)
    }

    @Test func onlyOneZoneTriggersPerTool() {
        let big = CGRect(x: 110, y: 130, width: 80, height: 60)
        let reading = read([tool(.brush, big)])
        let triggers = [reading.eyeTriggerLeft, reading.eyeTriggerRight, reading.noseTrigger, reading.lipsTrigger]
        #expect(triggers.filter { $0 }.count <= 1)
    }

    @Test func lockedLipsKeepsBrushNearTheBoundary() {
        let nearBoundary = CGRect(x: 146, y: 172, width: 8, height: 8)
        let free = read([tool(.brush, nearBoundary)])
        #expect(free.noseTrigger && !free.lipsTrigger)
        let locked = read([tool(.brush, nearBoundary)], locked: .lips)
        #expect(locked.lipsTrigger && !locked.noseTrigger)
        #expect(locked.lipsHold)
    }
}
