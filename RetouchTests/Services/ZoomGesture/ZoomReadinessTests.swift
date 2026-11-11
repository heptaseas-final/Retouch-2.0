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
}
