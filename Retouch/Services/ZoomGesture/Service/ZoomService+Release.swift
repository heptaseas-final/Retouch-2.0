//
//  ZoomService+Release.swift
//  Retouch
//
//  Created by Davin P on 19/11/26.
//

import Foundation

nonisolated extension ZoomService {
    func applyStraightRelease(eye: inout EyeZoomFlow.Input, lips: inout LipsZoomFlow.Input, nose: inout NoseZoomFlow.Input,
                              cheek: inout CheekZoomFlow.Input) {
        let handNear = eye.holdLeft || eye.holdRight || eye.toolHoldLeft || eye.toolHoldRight
            || eye.toolLeft || eye.toolRight || lips.fingerNear || lips.toolReady
            || nose.fingerNear || nose.toolReady
            || cheek.nearLeft || cheek.nearRight || cheek.readyLeft || cheek.readyRight
        guard headPose.isStraight, !handNear else { return }
        eye.handMovingAway = true
        lips.handMovingAway = true
        nose.handMovingAway = true
        cheek.handMovingAway = true
    }

    func newestHolding(_ owners: [FlowOwner], now: Date) -> FlowOwner? {
        for owner in FlowOwner.allCases where owners.contains(owner) && flowEnteredAt[owner] == nil {
            flowEnteredAt[owner] = now
        }
        for owner in FlowOwner.allCases where !owners.contains(owner) { flowEnteredAt[owner] = nil }
        return owners.max { (flowEnteredAt[$0] ?? .distantPast) < (flowEnteredAt[$1] ?? .distantPast) }
    }
}
