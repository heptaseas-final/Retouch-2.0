import Testing
@testable import Retouch

struct FacePartTests {
    @Test func autoZoomHasNoManualTarget() {
        #expect(FacePart.face.zoomTarget == nil)
    }

    @Test func partsMapToZoomTargets() {
        #expect(FacePart.leftEye.zoomTarget == .leftEye)
        #expect(FacePart.rightEye.zoomTarget == .rightEye)
        #expect(FacePart.mouth.zoomTarget == .lips)
        #expect(FacePart.nose.zoomTarget == .nose)
        #expect(FacePart.smile.zoomTarget == .fullFace)
    }
}
