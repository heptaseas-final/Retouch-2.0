//
//  RetouchUITestCase.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//

import XCTest

enum Name {
    static let mirror = "Mirror"
    static let glow = "Glow"
    static let settings = "Settings"
    static let zoomLevel = "Zoom level"
    static let zoomTarget = "Zoom target"
    static let lookDownZoom = "Look-down zoom"
    static let autoZoom = "AUTO ZOOM"
    static let overallCheck = "Overall check"
    static let roomLight = "Room light"
    static let lightMode = "Light"
    static let lightColor = "Light color"
    static let replay = "Replay Tutorial"
    static let skip = "Skip"
    static let openSettings = "Open Settings"
    static let permissionMessage = "Retouch needs your camera"
    static let cameraSwitch = "Camera"
}

enum Target {
    static let autoZoom = "Auto Zoom"
    static let leftEye = "Left Eye"
    static let lips = "Lips"
    static let nose = "Nose"
    static let fullFace = "Full Face"
    static let pickerStepCount = 6
}

enum Spoken {
    static let leftEye = "Left eye"
    static let lips = "Lips"
    static let nose = "Nose"
    static let fullFace = "Full face"
}

enum ZoomLevel {
    static let eye = 2.25
    static let mouth = 2.12
    static let nose = 1.9
    static let fullFace = 1.1
    static let widest = 1.0
    static let maximum = 3.0
    static let accuracy = 0.01
}

enum Layout {
    static let minimumTouchSize: CGFloat = 36
    static let bottomThirdStart: CGFloat = 2.0 / 3.0
}

class RetouchUITestCase: XCTestCase {
    var app = XCUIApplication()
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func launchApp(resetCamera: Bool = false, arguments: [String] = []) {
        app = XCUIApplication()
        if resetCamera { app.resetAuthorizationStatus(for: .camera) }
        app.launchArguments = ["-uiTesting"] + arguments
        app.launch()
    }

    func relaunchApp(arguments: [String] = []) {
        app.terminate()
        app.launchArguments = ["-uiTesting"] + arguments
        app.launch()
    }

    func openMirror(arguments: [String] = []) {
        launchApp(arguments: arguments)
        answerCameraAlert(allow: true)
        finishOnboardingIfShown()
    }

    @discardableResult
    func answerCameraAlert(allow: Bool, timeout: TimeInterval = 5) -> Bool {
        if allow, element(Name.zoomTarget).waitForExistence(timeout: 2) || app.buttons[Name.skip].exists {
            return false
        }
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: timeout) else { return false }
        tapButton(in: alert, allow: allow)
        return true
    }

    func tapButton(in alert: XCUIElement, allow: Bool) {
        let allowTitles = ["Allow", "OK"]
        let denyTitles = ["Don’t Allow", "Don't Allow"]
        let titles = allow ? allowTitles : denyTitles
        let predicate = NSPredicate(format: "label IN %@", titles)
        let button = alert.buttons.matching(predicate).firstMatch
        if button.waitForExistence(timeout: 2) {
            button.tap()
        }
    }

    func element(_ label: String) -> XCUIElement {
        app.descendants(matching: .any)[label].firstMatch
    }

    func require(_ label: String, _ tc: String, timeout: TimeInterval = 3) -> XCUIElement {
        let found = element(label)
        if !found.waitForExistence(timeout: timeout) {
            XCTFail("\(tc): elemen \"\(label)\" tidak ada di app")
        }
        return found
    }

    func text(_ element: XCUIElement) -> String {
        (element.value as? String) ?? element.label
    }

    func waitForMirrorTarget(_ expected: String, _ tc: String, timeout: TimeInterval = 3) {
        let mirror = require(Name.mirror, tc)
        let deadline = Date().addingTimeInterval(timeout)
        while text(mirror) != expected, Date() < deadline { pause(0.3) }
        XCTAssertEqual(text(mirror), expected, "\(tc): zoom tidak menuju \(expected)")
    }

    func pause(_ seconds: TimeInterval) {
        let wait = XCTestExpectation(description: "pause")
        wait.isInverted = true
        _ = XCTWaiter().wait(for: [wait], timeout: seconds)
    }

    func waitUntilGone(_ target: XCUIElement, timeout: TimeInterval = 3) -> Bool {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: target)
        return XCTWaiter().wait(for: [gone], timeout: timeout) == .completed
    }

    func finishOnboardingIfShown() {
        let skip = app.buttons[Name.skip]
        let controls = element(Name.zoomTarget)
        guard waitForFirst([skip, controls], timeout: 10) != nil, skip.exists else { return }
        skip.tap()
        _ = waitUntilGone(skip)
    }

    func showOnboarding(_ tc: String) {
        let skip = app.buttons[Name.skip]
        let menu = element(Name.settings)
        guard waitForFirst([skip, menu], timeout: 10) != nil else {
            XCTFail("\(tc): tidak ada Skip maupun Settings setelah 10 detik")
            return
        }
        if skip.exists { return }
        replayTutorial(tc)
        XCTAssertTrue(skip.waitForExistence(timeout: 3), "\(tc): overlay onboarding tidak muncul")
    }

    func replayTutorial(_ tc: String) {
        require(Name.settings, tc).tap()
        require(Name.replay, tc).tap()
    }

    func selectZoomTarget(_ title: String, _ tc: String) {
        let picker = require(Name.zoomTarget, tc)
        for _ in 0..<Target.pickerStepCount {
            if text(picker) == title { return }
            stepPicker(picker)
            pause(0.3)
        }
        XCTAssertEqual(text(picker), title, "\(tc): pilihan \"\(title)\" tidak ada di Zoom target")
    }

    func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func waitForFirst(_ candidates: [XCUIElement], timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if let found = candidates.first(where: { $0.exists }) { return found }
            pause(0.5)
        } while Date() < deadline
        return nil
    }
    
    func stepPicker(_ picker: XCUIElement) {
        let start = picker.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.5))
        let end = picker.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
    }
}
