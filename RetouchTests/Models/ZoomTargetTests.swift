import Testing
@testable import Retouch

struct ZoomTargetTests {
    @Test func spokenNamesMatchPickerNames() {
        #expect(ZoomTarget.fullFace.spokenName == "Full face")
        #expect(ZoomTarget.leftEye.spokenName == "Left eye")
        #expect(ZoomTarget.rightEye.spokenName == "Right eye")
        #expect(ZoomTarget.lips.spokenName == "Lips")
        #expect(ZoomTarget.nose.spokenName == "Nose")
        #expect(ZoomTarget.faceSide(.left).spokenName == "Left side of face")
        #expect(ZoomTarget.faceSide(.right).spokenName == "Right side of face")
        #expect(ZoomTarget.cheek(.left).spokenName == "Left cheek")
        #expect(ZoomTarget.cheek(.right).spokenName == "Right cheek")
    }

    @Test func announcementsNameTheZoomedPart() {
        #expect(ZoomTarget.leftEye.zoomAnnouncement == "Zoomed to left eye")
        #expect(ZoomTarget.faceSide(.right).zoomAnnouncement == "Zoomed to right side of face")
        #expect(ZoomTarget.fullFace.zoomAnnouncement == "Back to full face")
        #expect(ZoomTarget.cheek(.right).zoomAnnouncement == "Zoomed to right cheek")
    }
}
