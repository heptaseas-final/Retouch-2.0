//
//  LegacyAnalyticsEvent.swift
//  Retouch
//
//  Created by Davin P on 15/11/26.
//

import Foundation

nonisolated struct LegacyAnalyticsEvent: Codable, Equatable {
    let name: String
    let count: Int
    let durationSeconds: Double?
}
