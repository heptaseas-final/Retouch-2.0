//
//  LockZoomUITests.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//

import XCTest

final class LockZoomUITests: RetouchUITestCase {
    private func lock(_ title: String, _ tc: String) {
        openMirror()
        selectZoomTarget(title, tc)
    }

    func test_TC_3_4_05_lookDownZoomIsOffByDefault() {
        let tc = "TC-3.4-05"
        openMirror()
        XCTAssertEqual(text(require(Name.lookDownZoom, tc)), "Off", "\(tc): look-down zoom tidak off secara default")
    }

    func test_TC_3_6_01_lockMenuOpens() {
        let tc = "TC-3.6-01"
        openMirror()
        let picker = require(Name.zoomTarget, tc)
        var seen: Set<String> = []
        for _ in 0..<Target.pickerStepCount {
            seen.insert(text(picker))
            picker.swipeLeft()
            pause(0.3)
        }
        for title in [Target.leftEye, Target.lips, Target.nose, Target.fullFace] {
            XCTAssertTrue(seen.contains(title), "\(tc): pilihan \"\(title)\" tidak muncul")
        }
    }

    func test_TC_3_1_16_gestureMissedUseLockInstead() {
        let tc = "TC-3.1-16"
        lock(Target.leftEye, tc)
        XCTAssertEqual(zoomLevel(tc), ZoomLevel.eye, accuracy: ZoomLevel.accuracy, "\(tc): level zoom eye")
    }

    func test_TC_3_6_02_lockToEye() {
        let tc = "TC-3.6-02"
        lock(Target.leftEye, tc)
        XCTAssertEqual(zoomLevel(tc), ZoomLevel.eye, accuracy: ZoomLevel.accuracy, "\(tc): level zoom eye")
        XCTAssertNotEqual(text(element(Name.zoomTarget)), Target.autoZoom, "\(tc): Lock tidak aktif")
    }

    func test_TC_3_6_03_lockToMouth() {
        let tc = "TC-3.6-03"
        lock(Target.lips, tc)
        XCTAssertEqual(zoomLevel(tc), ZoomLevel.mouth, accuracy: ZoomLevel.accuracy, "\(tc): level zoom mouth")
    }

    func test_TC_3_6_04_lockToNose() {
        let tc = "TC-3.6-04"
        lock(Target.nose, tc)
        XCTAssertEqual(zoomLevel(tc), ZoomLevel.nose, accuracy: ZoomLevel.accuracy, "\(tc): level zoom nose")
    }

    func test_TC_3_6_05_lockToFullFace() {
        let tc = "TC-3.6-05"
        lock(Target.leftEye, tc)
        selectZoomTarget(Target.fullFace, tc)
        XCTAssertEqual(zoomLevel(tc), ZoomLevel.fullFace, accuracy: ZoomLevel.accuracy, "\(tc): level zoom full face")
    }

    func test_TC_3_6_08_lockTheCurrentViewAfterPinching() {
        let tc = "TC-3.6-08"
        openMirror()
        require(Name.mirror, tc).pinch(withScale: 2.2, velocity: 1)
        selectZoomTarget("CURRENT VIEW", tc)
        let before = zoomLevel(tc)
        pause(1)
        XCTAssertEqual(zoomLevel(tc), before, accuracy: ZoomLevel.accuracy, "\(tc): view pinch tidak bertahan")
    }

    func test_TC_3_6_09_slideBackToAutoZoomMode() {
        let tc = "TC-3.6-09"
        lock(Target.leftEye, tc)
        let picker = element(Name.zoomTarget)
        XCTAssertNotEqual(text(picker), Target.autoZoom, "\(tc): Lock tidak aktif")
        selectZoomTarget(Target.autoZoom, tc)
        XCTAssertEqual(text(picker), Target.autoZoom, "\(tc): tidak kembali ke auto zoom")
    }

    func test_TC_3_6_10_slideBackWhenAutoZoomWasOff() {
        let tc = "TC-3.6-10"
        openMirror()
        let autoZoom = require(Name.autoZoom, tc)
        autoZoom.tap()
        selectZoomTarget(Target.leftEye, tc)
        selectZoomTarget(Target.autoZoom, tc)
        XCTAssertEqual(text(autoZoom), "Off", "\(tc): auto zoom tidak tetap off")
    }

    func test_TC_3_6_11_turnAutoZoomOff() {
        let tc = "TC-3.6-11"
        openMirror()
        let autoZoom = require(Name.autoZoom, tc)
        autoZoom.tap()
        XCTAssertEqual(text(autoZoom), "Off", "\(tc): tombol auto zoom tidak off")
    }

    func test_TC_3_6_12_turnAutoZoomBackOn() {
        let tc = "TC-3.6-12"
        openMirror()
        let autoZoom = require(Name.autoZoom, tc)
        autoZoom.tap()
        autoZoom.tap()
        XCTAssertEqual(text(autoZoom), "On", "\(tc): tombol auto zoom tidak on")
    }

    func test_TC_3_6_14_pinchPastTheLimits() {
        let tc = "TC-3.6-14"
        openMirror()
        let mirror = require(Name.mirror, tc)
        mirror.pinch(withScale: 10, velocity: 2)
        XCTAssertLessThanOrEqual(zoomLevel(tc), ZoomLevel.maximum, "\(tc): zoom melewati batas atas")
        mirror.pinch(withScale: 0.1, velocity: -2)
        XCTAssertGreaterThanOrEqual(zoomLevel(tc), ZoomLevel.widest, "\(tc): zoom melewati batas bawah")
    }

    func test_TC_3_6_15_pinchingTurnsAutoZoomOff() {
        let tc = "TC-3.6-15"
        openMirror()
        require(Name.mirror, tc).pinch(withScale: 2, velocity: 1)
        XCTAssertEqual(text(require(Name.autoZoom, tc)), "Off", "\(tc): auto zoom tidak off setelah pinch")
    }

    func test_TC_3_6_16_buttonSizeAndPosition() {
        let tc = "TC-3.6-16"
        openMirror()
        let screenHeight = app.windows.firstMatch.frame.height
        for name in [Name.zoomTarget, Name.autoZoom] {
            let frame = require(name, tc).frame
            XCTAssertGreaterThanOrEqual(frame.width, Layout.minimumTouchSize, "\(tc): lebar \(name)")
            XCTAssertGreaterThanOrEqual(frame.height, Layout.minimumTouchSize, "\(tc): tinggi \(name)")
            XCTAssertGreaterThanOrEqual(frame.minY / screenHeight, Layout.bottomThirdStart, "\(tc): \(name) tidak di sepertiga bawah")
        }
    }

    func test_TC_3_6_17_relaunchResetsEverything() {
        let tc = "TC-3.6-17"
        lock(Target.leftEye, tc)
        require(Name.autoZoom, tc).tap()
        require(Name.lightMode, tc).tap()
        require(Name.lightColor, tc).tap()
        relaunchApp()
        finishOnboardingIfShown()
        XCTAssertEqual(text(require(Name.zoomTarget, tc)), Target.autoZoom, "\(tc): masih locked")
        XCTAssertEqual(zoomLevel(tc), ZoomLevel.widest, accuracy: ZoomLevel.accuracy, "\(tc): zoom bukan 1.0")
        XCTAssertEqual(text(require(Name.autoZoom, tc)), "On", "\(tc): auto zoom tidak on")
        XCTAssertEqual(text(require(Name.lightMode, tc)), "Auto", "\(tc): light tidak Auto")
    }

    func test_TC_3_6_18_lockWhenNoFaceIsVisible() {
        let tc = "TC-3.6-18"
        lock(Target.leftEye, tc)
        XCTAssertEqual(app.state, .runningForeground, "\(tc): app crash")
        attachScreenshot("\(tc) lock without face")
    }
}
