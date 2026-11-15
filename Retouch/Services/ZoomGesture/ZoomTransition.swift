//
//  ZoomTransition.swift
//  Retouch
//
//  Created by Davin P on 14/11/26.
//

import Foundation

nonisolated enum ZoomTransition: Equatable {
    case zoom
    case crossFade(duration: TimeInterval)

    static func style(reduceMotion: Bool) -> ZoomTransition {
        reduceMotion ? .crossFade(duration: ZoomTransitionConfig.reduceMotionFadeDuration) : .zoom
    }

    func fadeProgress(elapsed: TimeInterval) -> Double {
        switch self {
        case .zoom: 1
        case .crossFade(let duration): min(max(elapsed / duration, 0), 1)
        }
    }
}

nonisolated enum ZoomTransitionConfig {
    static let reduceMotionFadeDuration: TimeInterval = 0.2
}
