import Foundation
import Testing
@testable import Retouch

struct AnalyticsContextTests {
    private let context = AnalyticsContext(appVersion: "2.1", buildType: .appstore,
                                           iosVersion: "18.2.0", deviceModel: "iPhone16,1")
    private let tuesdayThreeUTC = Date(timeIntervalSince1970: 1_794_884_400)

    private func calendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier) ?? .gmt
        return calendar
    }

    @Test func propertiesCarryTheFixedValues() {
        let properties = context.properties(at: tuesdayThreeUTC, calendar: calendar("Asia/Jakarta"))
        #expect(properties["app_version"] == .string("2.1"))
        #expect(properties["build_type"] == .string("appstore"))
        #expect(properties["ios_version"] == .string("18.2.0"))
        #expect(properties["device_model"] == .string("iPhone16,1"))
    }

    @Test func localTimeFollowsTheCalendarTimeZone() {
        let jakarta = context.properties(at: tuesdayThreeUTC, calendar: calendar("Asia/Jakarta"))
        #expect(jakarta["local_hour"] == .int(10))
        #expect(jakarta["weekday"] == .int(3))
        #expect(jakarta["utc_offset"] == .double(7))
        let london = context.properties(at: tuesdayThreeUTC, calendar: calendar("Europe/London"))
        #expect(london["local_hour"] == .int(3))
        #expect(london["utc_offset"] == .double(0))
    }

    @Test func weekdayRollsOverWithTheLocalDate() {
        let lateEvening = Date(timeIntervalSince1970: 1_794_884_400 + 18 * 3600)
        let properties = context.properties(at: lateEvening, calendar: calendar("Asia/Jakarta"))
        #expect(properties["local_hour"] == .int(4))
        #expect(properties["weekday"] == .int(4))
    }

    @Test func sandboxReceiptMeansTestFlight() {
        #expect(AnalyticsContext.detectBuildType(receiptName: "sandboxReceipt") == .testflight)
    }

    @Test func storeReceiptMeansAppStore() {
        #expect(AnalyticsContext.detectBuildType(receiptName: "receipt") == .appstore)
    }

    @Test func missingReceiptIsNotCountedAsAppStore() {
        #expect(AnalyticsContext.detectBuildType(receiptName: nil) == .debug)
    }

    @Test func currentFillsEveryField() {
        let current = AnalyticsContext.current()
        #expect(!current.appVersion.isEmpty)
        #expect(!current.deviceModel.isEmpty)
        #expect(current.iosVersion.split(separator: ".").count == 3)
    }
}
