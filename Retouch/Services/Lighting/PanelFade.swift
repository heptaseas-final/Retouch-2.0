//
//  PanelFade.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 20/11/26.
//


import Foundation

nonisolated enum PanelFade {
    static func next(panel: Float, target: Float, dt: Float, fadeTime: Float, isLeavingManual: Bool) -> Float {
        guard !isLeavingManual else { return target }
        let tau = fadeTime * (target > panel ? 1 : 2)
        return panel + (target - panel) * (1 - exp(-dt / tau))
    }
}