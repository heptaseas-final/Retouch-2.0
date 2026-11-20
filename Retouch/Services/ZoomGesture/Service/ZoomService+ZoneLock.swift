//
//  ZoomService+ZoneLock.swift
//  Retouch
//
//  Created by Alif Tito Shiddiq ArRosyid on 19/11/26.
//

import CoreGraphics
import Foundation

nonisolated extension ZoomService {
    var zoneReach: CGFloat {
        min(CGFloat(handProfile.enterDistance / ZoomTuning.handEnterDistance), ZoomTuning.maxTriggerScale)
    }

    var zoneLipsReach: CGFloat {
        let support = ZoomTuning.pitchEnabled && ZoomTuning.pitchHandSupportEnabled && pitchRecognizer.isLifted
        return CGFloat(handProfile.enterDistance) * (support ? ZoomTuning.pitchLipsReach : 1)
    }

    var zonesAnchored: Bool { eyeFlow.isActive || lipFlow.isActive || noseFlow.isActive }

    func applyZoneLock(eye: inout EyeZoomFlow.Input, lips: inout LipsZoomFlow.Input,
                       nose: inout NoseZoomFlow.Input) {
        let floor = ZoomTuning.zoneSwitchDwell
        if lipFlow.isActive || noseFlow.isActive { eye.enterFloor = floor }
        if eyeFlow.isActive || noseFlow.isActive { lips.enterFloor = floor }
        if eyeFlow.isActive || lipFlow.isActive { nose.enterFloor = floor }

        let switching = eyeFlow.phase == .entering || lipFlow.phase == .entering || noseFlow.phase == .entering
        guard switching else { return }
        if eyeFlow.isActive, let side = eyeFlow.side {
            if side == .left { eye.holdLeft = true } else { eye.holdRight = true }
        }
        if lipFlow.isActive { lips.fingerNear = true }
        if noseFlow.isActive { nose.fingerNear = true }
    }
}
