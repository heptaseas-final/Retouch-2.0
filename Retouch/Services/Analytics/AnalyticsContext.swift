import Foundation

nonisolated enum AnalyticsBuildType: String, Sendable {
    case debug, testflight, appstore
}

nonisolated struct AnalyticsContext: Sendable, Equatable {
    var appVersion: String
    var buildType: AnalyticsBuildType
    var iosVersion: String
    var deviceModel: String

    func properties(at date: Date, calendar: Calendar = .current) -> [String: AnalyticsValue] {
        let offsetSeconds = calendar.timeZone.secondsFromGMT(for: date)
        return [
            "app_version": .string(appVersion),
            "build_type": .string(buildType.rawValue),
            "ios_version": .string(iosVersion),
            "device_model": .string(deviceModel),
            "local_hour": .int(calendar.component(.hour, from: date)),
            "weekday": .int(calendar.component(.weekday, from: date)),
            "utc_offset": .double(Double(offsetSeconds) / AnalyticsConfig.secondsPerHour)
        ]
    }

    static func detectBuildType(receiptName: String?) -> AnalyticsBuildType {
        switch receiptName {
        case AnalyticsConfig.sandboxReceiptName: .testflight
        case .some: .appstore
        case nil: .debug
        }
    }

    static func current(bundle: Bundle = .main) -> AnalyticsContext {
        let system = ProcessInfo.processInfo.operatingSystemVersion
        #if DEBUG
        let type = AnalyticsBuildType.debug
        #else
        let type = detectBuildType(receiptName: bundle.appStoreReceiptURL?.lastPathComponent)
        #endif
        return AnalyticsContext(
            appVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                ?? AnalyticsConfig.unknownValue,
            buildType: type,
            iosVersion: "\(system.majorVersion).\(system.minorVersion).\(system.patchVersion)",
            deviceModel: machineIdentifier())
    }

    private static func machineIdentifier() -> String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: info.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
