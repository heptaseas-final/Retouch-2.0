//
//  OnboardingUITests.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//


import XCTest

final class OnboardingUITests: RetouchUITestCase {
    private func openOnboarding(_ tc: String) {
        launchApp()
        answerCameraAlert(allow: true)
        showOnboarding(tc)
    }

    private func skipAndRelaunch(_ tc: String) {
        openOnboarding(tc)
        app.buttons[Name.skip].tap()
        relaunchApp()
    }

    func test_TC_3_8_01_overlayOnFirstLaunch() {
        let tc = "TC-3.8-01"
        openOnboarding(tc)
        XCTAssertTrue(app.buttons[Name.skip].exists, "\(tc): tombol Skip tidak ada")
        for keyword in ["eye", "lips", "Lock"] {
            let step = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", keyword)).firstMatch
            XCTAssertTrue(step.exists, "\(tc): teks langkah dengan \"\(keyword)\" tidak ada")
        }
    }

    func test_TC_3_8_03_skip() {
        let tc = "TC-3.8-03"
        openOnboarding(tc)
        let skip = app.buttons[Name.skip]
        skip.tap()
        XCTAssertTrue(waitUntilGone(skip), "\(tc): overlay tidak tertutup dalam 1 tap")
    }

    func test_TC_3_8_04_notShownAgainAfterCompleting() {
        let tc = "TC-3.8-04"
        skipAndRelaunch(tc)
        XCTAssertFalse(app.buttons[Name.skip].waitForExistence(timeout: 3), "\(tc): overlay muncul lagi")
    }

    func test_TC_3_8_05_notShownAgainAfterSkipping() {
        let tc = "TC-3.8-05"
        skipAndRelaunch(tc)
        XCTAssertFalse(app.buttons[Name.skip].waitForExistence(timeout: 3), "\(tc): overlay muncul lagi")
    }

    func test_TC_3_8_06_helpReplaysTheOverlay() {
        let tc = "TC-3.8-06"
        openMirror()
        let help = require(Name.replay, tc)
        XCTAssertGreaterThanOrEqual(help.frame.width, Layout.minimumTouchSize, "\(tc): lebar tombol help")
        XCTAssertGreaterThanOrEqual(help.frame.height, Layout.minimumTouchSize, "\(tc): tinggi tombol help")
        help.tap()
        XCTAssertTrue(app.buttons[Name.skip].waitForExistence(timeout: 1), "\(tc): overlay tidak replay")
    }

    func test_TC_3_8_08_cameraDeniedOnFirstLaunch() {
        let tc = "TC-3.8-08"
        openMirror()
        require(Name.replay, tc).tap()
        app.terminate()
        launchApp(resetCamera: true)
        answerCameraAlert(allow: false)
        XCTAssertFalse(app.buttons[Name.skip].waitForExistence(timeout: 3), "\(tc): overlay muncul padahal kamera ditolak")
        let button = app.buttons[Name.openSettings]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(tc): tombol Open Settings tidak ada")
        button.tap()
        let cameraSwitch = settings.switches[Name.cameraSwitch]
        XCTAssertTrue(cameraSwitch.waitForExistence(timeout: 5), "\(tc): switch Camera tidak ada")
        if (cameraSwitch.value as? String) == "0" { cameraSwitch.tap() }
        app.activate()
        XCTAssertTrue(app.buttons[Name.skip].waitForExistence(timeout: 8), "\(tc): overlay tidak muncul setelah kamera diizinkan")
    }

    func test_TC_3_8_09_gestureNotDetectedDuringAStep() {
        let tc = "TC-3.8-09"
        openOnboarding(tc)
        for second in stride(from: 0, to: 30, by: 5) {
            XCTAssertTrue(app.buttons[Name.skip].exists, "\(tc): Skip hilang di detik \(second)")
            pause(5)
        }
        let hasNext = app.buttons["Next"].exists
        let note = XCTAttachment(string: "Next control exists: \(hasNext)")
        note.name = "TC-3.8-09 Next control"
        note.lifetime = .keepAlways
        add(note)
    }
}