//
//  AnalyticsPrivacyTests.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//


import Foundation
import Testing
@testable import Retouch

struct AnalyticsPrivacyTests {
//    @Test("TC-5.2-05 Analytics events carry no image data")
//    func analyticsEventsCarryNoImageData() {
//        Issue.record("TC-5.2-05: analytics belum ada di code, tidak ada event untuk di-encode")
//    }

    @Test("TC-5.2-05 Analytics events carry no image data")
    func analyticsEventsCarryNoImageData() throws {
        let event = AnalyticsEvent(name: "zoom_changed", count: 1, durationSeconds: 0.2)
        let data = try JSONEncoder().encode(event)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let forbidden = ["image", "video", "frame", "landmark", "pixel", "photo"]
        for key in json.keys {
            #expect(!forbidden.contains { key.lowercased().contains($0) })
        }
        #expect(data.count < 1_000)
        let holdsImageData = Mirror(reflecting: event).children.contains { $0.value is Data }
        #expect(!holdsImageData)
    }
}
