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

//    func test_TC_3_4_05_lookDownZoomIsOffByDefault() {
//        let tc = "TC-3.4-05"
//        openMirror()
//        XCTAssertEqual(text(require(Name.lookDownZoom, tc)), "Off", "\(tc): look-down zoom tidak off secara default")
//    }

    func test_TC_3_6_01_lockMenuOpens() {
        let tc = "TC-3.6-01"
        openMirror()
        let picker = require(Name.zoomTarget, tc)
        var seen: Set<String> = []
        for _ in 0..<Target.pickerStepCount {
            seen.insert(text(picker))
            stepPicker(picker)
            pause(0.3)
        }
        for title in [Target.leftEye, Target.lips, Target.nose, Target.fullFace] {
            XCTAssertTrue(seen.contains(title), "\(tc): pilihan \"\(title)\" tidak muncul")
        }
    }

    func test_TC_3_1_16_gestureMissedUseLockInstead() {
        let tc = "TC-3.1-16"
        lock(Target.leftEye, tc)
        waitForMirrorTarget(Spoken.leftEye, tc)
    }

    func test_TC_3_6_02_lockToEye() {
        let tc = "TC-3.6-02"
        lock(Target.leftEye, tc)
        waitForMirrorTarget(Spoken.leftEye, tc)
        XCTAssertNotEqual(text(element(Name.zoomTarget)), Target.autoZoom, "\(tc): Lock tidak aktif")
    }

    func test_TC_3_6_03_lockToMouth() {
        let tc = "TC-3.6-03"
        lock(Target.lips, tc)
        waitForMirrorTarget(Spoken.lips, tc)
    }

    func test_TC_3_6_04_lockToNose() {
        let tc = "TC-3.6-04"
        lock(Target.nose, tc)
        waitForMirrorTarget(Spoken.nose, tc)
    }

    func test_TC_3_6_05_lockToFullFace() {
        let tc = "TC-3.6-05"
        lock(Target.leftEye, tc)
        selectZoomTarget(Target.fullFace, tc)
        waitForMirrorTarget(Spoken.fullFace, tc)
    }

//    func test_TC_3_6_08_lockTheCurrentViewAfterPinching() throws {
//        throw XCTSkip("TC-3.6-08: sudah di test manual")
//    }

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
        let picker = require(Name.zoomTarget, tc)
        selectZoomTarget(Target.lips, tc)
        selectZoomTarget(Target.leftEye, tc)
        XCTAssertNotEqual(text(picker), Target.autoZoom, "\(tc): zoom manual tidak aktif")
        selectZoomTarget(Target.autoZoom, tc)
        XCTAssertEqual(text(picker), Target.autoZoom, "\(tc): auto zoom tidak nyala setelah geser balik")
    }

    func test_TC_3_6_11_turnAutoZoomOff() {
        let tc = "TC-3.6-11"
        openMirror()
        let picker = require(Name.zoomTarget, tc)
        XCTAssertEqual(text(picker), Target.autoZoom, "\(tc): auto zoom tidak nyala di awal")
        selectZoomTarget(Target.lips, tc)
        XCTAssertNotEqual(text(picker), Target.autoZoom, "\(tc): auto zoom tidak mati")
    }

    func test_TC_3_6_12_turnAutoZoomBackOn() {
        let tc = "TC-3.6-12"
        openMirror()
        let picker = require(Name.zoomTarget, tc)
        selectZoomTarget(Target.lips, tc)
        selectZoomTarget(Target.autoZoom, tc)
        XCTAssertEqual(text(picker), Target.autoZoom, "\(tc): auto zoom tidak nyala lagi")
    }

    func test_TC_3_6_14_pinchPastTheLimits() {
        let tc = "TC-3.6-14"
        openMirror()
        let mirror = require(Name.mirror, tc)
        mirror.pinch(withScale: 10, velocity: 2)
        pause(0.5)
        XCTAssertEqual(app.state, .runningForeground, "\(tc): app crash saat pinch melewati batas atas")
        XCTAssertTrue(mirror.exists, "\(tc): mirror hilang setelah pinch melewati batas atas")
        mirror.pinch(withScale: 0.1, velocity: -2)
        pause(0.5)
        XCTAssertEqual(app.state, .runningForeground, "\(tc): app crash saat pinch melewati batas bawah")
        XCTAssertTrue(mirror.exists, "\(tc): mirror hilang setelah pinch melewati batas bawah")
    }

    func test_TC_3_6_15_pinchingTurnsAutoZoomOff() {
        let tc = "TC-3.6-15"
        openMirror()
        let picker = require(Name.zoomTarget, tc)
        XCTAssertEqual(text(picker), Target.autoZoom, "\(tc): auto zoom tidak nyala di awal")
        require(Name.mirror, tc).pinch(withScale: 2, velocity: 1)
        pause(0.5)
        XCTAssertEqual(text(picker), Target.fullFace, "\(tc): mode tidak berubah ke Full Face setelah pinch")
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
        require(Name.lightMode, tc).tap()
        require(Name.lightColor, tc).tap()
        relaunchApp()
        finishOnboardingIfShown()
        XCTAssertEqual(text(require(Name.zoomTarget, tc)), Target.autoZoom, "\(tc): masih locked")
        XCTAssertEqual(text(require(Name.mirror, tc)), "Full face", "\(tc): zoom tidak kembali ke full face")
        XCTAssertEqual(text(require(Name.lightMode, tc)), "Off", "\(tc): light tidak Auto")
    }

    func test_TC_3_6_18_lockWhenNoFaceIsVisible() {
        let tc = "TC-3.6-18"
        lock(Target.leftEye, tc)
        XCTAssertEqual(app.state, .runningForeground, "\(tc): app crash")
        attachScreenshot("\(tc) lock without face")
    }
}
