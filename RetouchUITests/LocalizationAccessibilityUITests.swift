//
//  LocalizationAccessibilityUITests.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//

import XCTest

final class LocalizationAccessibilityUITests: RetouchUITestCase {
    private func languageArguments(_ code: String) -> [String] {
        ["-AppleLanguages", "(\(code))", "-AppleLocale", code]
    }

//    func test_TC_1_2_09_bannerTextInBahasaIndonesia() throws {
//        throw XCTSkip("TC-1.2-09: N/A di PRD v3.1, app English only")
//    }

//    func test_TC_5_4_01_allScreensInBahasaIndonesia() throws {
//        throw XCTSkip("TC-5.4-01: N/A di PRD v3.1, app English only")
//    }

    func test_TC_5_4_02_allScreensInEnglish() {
        let tc = "TC-5.4-02"
        launchApp(arguments: languageArguments("en"))
        answerCameraAlert(allow: true)
        showOnboarding(tc)
        attachScreenshot("\(tc) onboarding")
        app.buttons[Name.skip].tap()
        XCTAssertTrue(element(Name.lightMode).waitForExistence(timeout: 3), "\(tc): label Light tidak English")
        XCTAssertTrue(element(Name.zoomTarget).exists, "\(tc): label Zoom target tidak English")
        XCTAssertTrue(element(Name.settings).exists, "\(tc): label Settings tidak English")
        attachScreenshot("\(tc) mirror")
    }

    func test_TC_5_4_03_iPhoneSetToAnotherLanguage() {
        let tc = "TC-5.4-03"
        for code in ["id", "ja"] {
            launchApp(arguments: languageArguments(code))
            answerCameraAlert(allow: true)
            finishOnboardingIfShown()
            XCTAssertTrue(element(Name.lightMode).waitForExistence(timeout: 3), "\(tc): label Light tidak English di \(code)")
            XCTAssertTrue(element(Name.zoomTarget).exists, "\(tc): Zoom target tidak English di \(code)")
            app.terminate()
        }
    }

    func test_TC_5_4_04_voiceOverLabels() throws {
        let tc = "TC-5.4-04"
        openMirror()
        for button in app.buttons.allElementsBoundByIndex {
            XCTAssertFalse(button.label.isEmpty, "\(tc): tombol tanpa label di \(button.frame)")
        }
        try app.performAccessibilityAudit(for: .sufficientElementDescription)
    }

    func test_TC_5_4_05_largestDynamicType() throws {
        openMirror(arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"])
        try app.performAccessibilityAudit(for: .textClipped)
    }

    func test_TC_5_4_07_rotation() {
        let tc = "TC-5.4-07"
        openMirror()
        addTeardownBlock { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .landscapeLeft
        pause(1)
        let frame = app.windows.firstMatch.frame
        XCTAssertGreaterThan(frame.height, frame.width, "\(tc): app ikut berputar ke landscape")
        XCUIDevice.shared.orientation = .portrait
    }
}
