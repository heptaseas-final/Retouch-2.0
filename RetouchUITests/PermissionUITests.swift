//
//  PermissionUITests.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//

import XCTest

final class PermissionUITests: RetouchUITestCase {
    private func launchDenied() {
        launchApp(resetCamera: true)
        answerCameraAlert(allow: false)
    }

    private func collectPromptLabels(timeout: TimeInterval) -> [String] {
        var labels: [String] = []
        for _ in 0..<5 {
            let alert = springboard.alerts.firstMatch
            guard alert.waitForExistence(timeout: timeout) else { break }
            labels.append(alert.label)
            tapButton(in: alert, allow: true)
        }
        return labels
    }

    func test_TC_1_1_07_cameraDeniedOnFirstLaunch() {
        launchDenied()
        XCTAssertTrue(element(Name.permissionMessage).waitForExistence(timeout: 5), "TC-1.1-07: pesan izin kamera tidak muncul")
        XCTAssertTrue(app.buttons[Name.openSettings].exists, "TC-1.1-07: tombol Open Settings tidak ada")
        XCTAssertEqual(app.state, .runningForeground, "TC-1.1-07: app crash")
    }

    func test_TC_1_1_08_settingsButtonOpensRetouchPage() {
        launchDenied()
        let button = app.buttons[Name.openSettings]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "TC-1.1-08: tombol Open Settings tidak ada")
        button.tap()
        XCTAssertTrue(settings.wait(for: .runningForeground, timeout: 5), "TC-1.1-08: Settings tidak terbuka")
        XCTAssertTrue(settings.switches[Name.cameraSwitch].waitForExistence(timeout: 5), "TC-1.1-08: halaman Retouch tidak terbuka")
    }

    func test_TC_1_1_09_cameraAllowedLaterFromSettings() {
        launchDenied()
        let button = app.buttons[Name.openSettings]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "TC-1.1-09: tombol Open Settings tidak ada")
        button.tap()
        let cameraSwitch = settings.switches[Name.cameraSwitch]
        XCTAssertTrue(cameraSwitch.waitForExistence(timeout: 5), "TC-1.1-09: switch Camera tidak ada")
        if (cameraSwitch.value as? String) == "0" { cameraSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap() }
        app.activate()
        XCTAssertTrue(waitUntilGone(element(Name.permissionMessage)), "TC-1.1-09: pesan izin masih tampil")
        XCTAssertEqual(app.state, .runningForeground, "TC-1.1-09: app crash")
    }

    func test_TC_1_1_12_returnAfter30SecondsInBackground() {
        openMirror()
        XCTAssertTrue(element(Name.zoomTarget).waitForExistence(timeout: 5), "TC-1.1-12: mirror tidak tampil")
        XCUIDevice.shared.press(.home)
        pause(30)
        app.activate()
        XCTAssertTrue(element(Name.zoomTarget).waitForExistence(timeout: 1), "TC-1.1-12: mirror tidak kembali dalam 1 s")
    }

    func test_TC_5_2_04_cameraIsTheOnlyPermissionPrompt() {
        launchApp(resetCamera: true)
        var prompts = collectPromptLabels(timeout: 5)
        finishOnboardingIfShown()
        if element(Name.lightMode).exists { element(Name.lightMode).tap() }
        if element(Name.zoomTarget).exists { stepPicker(element(Name.zoomTarget)) }
        prompts += collectPromptLabels(timeout: 3)
        XCTAssertEqual(prompts.count, 1, "TC-5.2-04: prompt yang muncul: \(prompts)")
        XCTAssertTrue(prompts.first?.localizedCaseInsensitiveContains("camera") ?? false, "TC-5.2-04: prompt pertama bukan kamera: \(prompts)")
    }
}
