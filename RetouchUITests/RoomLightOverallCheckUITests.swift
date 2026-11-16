//
//  RoomLightOverallCheckUITests.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//

import XCTest

final class RoomLightOverallCheckUITests: RetouchUITestCase {
    private func zoomIn(to scale: CGFloat, _ tc: String) {
        openMirror()
        require(Name.mirror, tc).pinch(withScale: scale, velocity: 1)
    }

    func test_TC_4_2_06_changingLightWhileRoomLightIsOn() {
        let tc = "TC-4.2-06"
        openMirror()
        let roomLight = require(Name.roomLight, tc)
        roomLight.tap()
        require(Name.lightMode, tc).tap()
        require(Name.lightColor, tc).tap()
        let note = XCTAttachment(string: "Room light state: \(text(roomLight))")
        note.name = "\(tc) Room light state"
        note.lifetime = .keepAlways
        add(note)
        XCTAssertEqual(app.state, .runningForeground, "\(tc): app crash")
    }

    func test_TC_4_2_07_relaunchWithRoomLightOn() {
        let tc = "TC-4.2-07"
        openMirror()
        require(Name.roomLight, tc).tap()
        relaunchApp()
        finishOnboardingIfShown()
        XCTAssertEqual(text(require(Name.roomLight, tc)), "Off", "\(tc): Room light tidak off setelah relaunch")
    }

    func test_TC_4_3_01_overallCheckButtonFromCloseZoom() {
        let tc = "TC-4.3-01"
        zoomIn(to: 3, tc)
        require(Name.overallCheck, tc).tap()
        XCTAssertEqual(zoomLevel(tc), ZoomLevel.widest, accuracy: ZoomLevel.accuracy, "\(tc): zoom tidak kembali ke full view")
    }

    func test_TC_4_3_02_overallCheckButtonFromSlightZoom() {
        let tc = "TC-4.3-02"
        zoomIn(to: 1.5, tc)
        require(Name.overallCheck, tc).tap()
        XCTAssertEqual(zoomLevel(tc), ZoomLevel.widest, accuracy: ZoomLevel.accuracy, "\(tc): zoom tidak kembali ke full view")
    }

    func test_TC_4_3_03_buttonWhileLocked() {
        let tc = "TC-4.3-03"
        openMirror()
        selectZoomTarget(Target.lips, tc)
        require(Name.overallCheck, tc).tap()
        XCTAssertEqual(text(element(Name.zoomTarget)), Target.autoZoom, "\(tc): Lock tidak dilepas")
        XCTAssertEqual(zoomLevel(tc), ZoomLevel.widest, accuracy: ZoomLevel.accuracy, "\(tc): zoom bukan full view")
    }

    func test_TC_4_3_05_buttonSizeAndReach() {
        let tc = "TC-4.3-05"
        openMirror()
        let frame = require(Name.overallCheck, tc).frame
        let screenHeight = app.windows.firstMatch.frame.height
        XCTAssertGreaterThanOrEqual(frame.width, Layout.minimumTouchSize, "\(tc): lebar tombol")
        XCTAssertGreaterThanOrEqual(frame.height, Layout.minimumTouchSize, "\(tc): tinggi tombol")
        XCTAssertGreaterThanOrEqual(frame.minY / screenHeight, Layout.bottomThirdStart, "\(tc): tombol tidak di sepertiga bawah")
    }
}
