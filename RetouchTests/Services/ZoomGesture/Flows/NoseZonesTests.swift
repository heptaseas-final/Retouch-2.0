import CoreGraphics
import Testing
@testable import Retouch

struct NoseZonesTests {
    private func makeZones() -> NoseZones? {
        var points = FacePoints()
        points.leftEye = CGPoint(x: 100, y: 100)
        points.rightEye = CGPoint(x: 200, y: 100)
        points.lips = CGPoint(x: 150, y: 220)
        points.nose = CGPoint(x: 150, y: 145)
        points.width = 260
        points.scale = 100
        return NoseZones(points: points)
    }

    @Test func noseTipIsNose() throws {
        let zones = try #require(makeZones())
        #expect(zones.inTrigger(CGPoint(x: 150, y: 145)))
        #expect(zones.holds(CGPoint(x: 150, y: 145)))
    }

    @Test func innerEyeCornerStaysWithEye() throws {
        let zones = try #require(makeZones())
        #expect(!zones.inTrigger(CGPoint(x: 130, y: 130)))
        #expect(!zones.holds(CGPoint(x: 130, y: 130)))
    }

    @Test func eyeLineIsNotNose() throws {
        let zones = try #require(makeZones())
        #expect(!zones.inTrigger(CGPoint(x: 150, y: 110)))
    }

    @Test func lipsSideIsNotNose() throws {
        let zones = try #require(makeZones())
        #expect(!zones.inTrigger(CGPoint(x: 150, y: 190)))
    }

    @Test func cheekBesideNoseIsNotNose() throws {
        let zones = try #require(makeZones())
        #expect(!zones.inTrigger(CGPoint(x: 200, y: 150)))
    }

    @Test func eyeTriggerNeverOverlapsNose() throws {
        let zones = try #require(makeZones())
        var points = FacePoints()
        points.leftEye = CGPoint(x: 100, y: 100)
        points.rightEye = CGPoint(x: 200, y: 100)
        points.lips = CGPoint(x: 150, y: 220)
        points.scale = 100
        var eyes = try #require(EyeZones(points: points))
        eyes.triggerScale = ZoomTuning.maxTriggerScale
        for x in stride(from: 80.0, through: 220.0, by: 5.0) {
            for y in stride(from: 80.0, through: 200.0, by: 5.0) {
                let p = CGPoint(x: x, y: y)
                guard zones.inTrigger(p) else { continue }
                #expect(eyes.gripTriggerEye(at: p) == nil)
            }
        }
    }
}
