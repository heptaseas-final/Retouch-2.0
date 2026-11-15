//
//  RetouchUITestCase.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//

import XCTest

enum Name {
    static let mirror = "Mirror view"
    static let zoomLevel = "Zoom level"
    static let zoomTarget = "Zoom target"
    static let lookDownZoom = "Look-down zoom"
    static let autoZoom = "Auto zoom"
    static let overallCheck = "Overall check"
    static let roomLight = "Room light"
    static let lightMode = "Light mode"
    static let lightColor = "Light color"
    static let replay = "Replay tutorial"
    static let skip = "Skip"
    static let openSettings = "Open Settings"
    static let permissionMessage = "Turn on the camera permission"
    static let cameraSwitch = "Camera"
}

enum Target {
    static let autoZoom = "AUTO ZOOM"
    static let leftEye = "LEFT EYE"
    static let lips = "LIPS"
    static let nose = "NOSE"
    static let fullFace = "FULL FACE"
    static let pickerStepCount = 6
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
    static let minimumTouchSize: CGFloat = 44
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
        app.launchArguments = arguments
        app.launch()
    }

    func relaunchApp(arguments: [String] = []) {
        app.terminate()
        app.launchArguments = arguments
        app.launch()
    }

    func openMirror(arguments: [String] = []) {
        launchApp(arguments: arguments)
        answerCameraAlert(allow: true)
        finishOnboardingIfShown()
    }

    @discardableResult
    func answerCameraAlert(allow: Bool, timeout: TimeInterval = 5) -> Bool {
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: timeout) else { return false }
        tapButton(in: alert, allow: allow)
        return true
    }

    func tapButton(in alert: XCUIElement, allow: Bool) {
        let allowTitles = ["Allow", "OK"]
        let denyTitles = ["Don’t Allow", "Don't Allow"]
        for title in allow ? allowTitles : denyTitles where alert.buttons[title].exists {
            alert.buttons[title].tap()
            return
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

    func zoomLevel(_ tc: String) -> Double {
        Double(text(require(Name.zoomLevel, tc))) ?? .nan
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
        guard skip.waitForExistence(timeout: 2) else { return }
        skip.tap()
        _ = waitUntilGone(skip)
    }

    func showOnboarding(_ tc: String) {
        let skip = app.buttons[Name.skip]
        if skip.waitForExistence(timeout: 2) { return }
        require(Name.replay, tc).tap()
        XCTAssertTrue(skip.waitForExistence(timeout: 3), "\(tc): overlay onboarding tidak muncul")
    }

    func selectZoomTarget(_ title: String, _ tc: String) {
        let picker = require(Name.zoomTarget, tc)
        for _ in 0..<Target.pickerStepCount {
            if text(picker) == title { return }
            picker.swipeLeft()
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
}
