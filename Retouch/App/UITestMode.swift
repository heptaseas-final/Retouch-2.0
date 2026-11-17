//
//  UITestMode.swift
//  Retouch
//
//  Created by Davin P on 16/11/26.
//


import Foundation

nonisolated enum UITestMode {
    static let isActive = CommandLine.arguments.contains("-uiTesting")
    static let forcesGlowMaximum = isActive && CommandLine.arguments.contains("-forceGlowMaximum")
}
