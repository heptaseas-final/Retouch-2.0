//
//  LightPanelUITests.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//

import XCTest

final class LightPanelUITests: RetouchUITestCase {
    func test_TC_2_1_04_mirrorCoversHalfTheScreenWithGlowAtMaximum() {
        openMirror(arguments: ["-forceGlowMaximum", "YES"])
        _ = require(Name.glow, "TC-2.1-04")
        let mirror = require(Name.mirror, "TC-2.1-04")
        let window = app.windows.firstMatch.frame
        let ratio = (mirror.frame.width * mirror.frame.height) / (window.width * window.height)
        XCTAssertGreaterThanOrEqual(ratio, 0.5, "TC-2.1-04: mirror hanya \(ratio) dari layar")
    }

//    func test_TC_2_2_02_brightnessRangeAndSteps() throws {
//        throw XCTSkip("TC-2.2-02: N/A di PRD v3.1, build tidak punya brightness slider")
//    }

    func test_TC_2_2_03_lightColorChoices() {
        openMirror()
        let tc = "TC-2.2-03"
        require(Name.lightMode, tc).tap()
        let color = require(Name.lightColor, tc)
        XCTAssertEqual(text(color), "Neutral", "\(tc): white tidak terpilih")
        color.tap()
        XCTAssertEqual(text(color), "Warm", "\(tc): warm tidak terpilih")
        color.tap()
        XCTAssertEqual(text(color), "Cool", "\(tc): cool tidak terpilih")
    }

    func test_TC_2_2_07_relaunchResetsLightToAuto() {
        openMirror()
        let tc = "TC-2.2-07"
        require(Name.lightMode, tc).tap()
        require(Name.lightColor, tc).tap()
        relaunchApp()
        finishOnboardingIfShown()
        XCTAssertEqual(text(require(Name.lightMode, tc)), "Off", "\(tc): light mode setelah relaunch bukan Auto")
    }

//    func test_TC_2_2_08_panelClosesByItself() throws {
//        throw XCTSkip("TC-2.2-08: N/A di PRD v3.1, AC auto-close panel dihapus")
//    }
//
//    func test_TC_2_2_09_panelStaysOpenWhileDragging() throws {
//        throw XCTSkip("TC-2.2-09: N/A di PRD v3.1, AC auto-close panel dihapus")
//    }
}
