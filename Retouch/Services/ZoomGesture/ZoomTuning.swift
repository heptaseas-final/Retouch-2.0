import Foundation
import CoreImage
import Vision

nonisolated struct ZoomTuning {
    static let detectionRate = 8.0
    static let fairRate = 6.0
    static let seriousRate = 4.0
    static let idleRate = 4.0
    static let idleAfter: TimeInterval = 3.0
    static let idleFaceSpeed = 0.3
    static let idleYawRate = 25.0
    static let envCheckInterval: TimeInterval = 2.0
    static let strainFps = 27.0
    static let strainRecoverFps = 29.5
    static let strainEnterAfter: TimeInterval = 1.5
    static let strainExitAfter: TimeInterval = 8.0

    static let downscaleEnabled = true
    static let analysisWidth: CGFloat = 480

    static let yawTau = 0.15
    static let pointTau: CGFloat = 0.1
    static let scaleTau: CGFloat = 0.65
    static let handSpeedTau: CGFloat = 0.15
    static let fullFaceZoom: CGFloat = 1.1
    static let eyeZoomScale: CGFloat = 2.25
    static let lipsZoomScale: CGFloat = 2.12
    static let noseZoomScale: CGFloat = 1.9

    static let sideZoom: CGFloat = 1.6

    static let overallZoom: CGFloat = 1.0
    static let overallEnterWidth = 0.24
    static let overallExitWidth = 0.27
    static let overallMinYawCos = 0.5
    static let reseedMinYawCos = 0.6
    static let sideEnterDwell: TimeInterval = 0.5
    static let sideExitDwell: TimeInterval = 0.7
    static let sideFocusStrength: CGFloat = 1
    static let sideFocusOutward: CGFloat = 0.30
    static let sideFocusDrop: CGFloat = 0.3
    static let sideResolverExitHold: TimeInterval = 0.3
    static let sideFastExitEnabled = true
    static let sideFastExitTravel = 55.0
    static let sideFastExitTravelTau = 0.5
    static let sideFastExitArmDelay: TimeInterval = 0.6

    static let handEnterDistance = 0.38
    static let handMaxSpeed = 1.2
    static let coverDistance: CGFloat = 0.65
    static let coverGrace: TimeInterval = 1.8
    static let coverHold: TimeInterval = 0.8
    static let faceLostClear: TimeInterval = 1.0
    static let faceLostClearCovering: TimeInterval = 3.0
    static let resolverExitCooldown: TimeInterval = 0.6
    static let coverFollowEnabled = true
    static let coverFollowMinScale: CGFloat = 0.8
    static let coverFollowMaxScale: CGFloat = 1.25
    static let anchorYawLimit = 10.0
    static let anchorBlendTau: TimeInterval = 1.5
    static let widthTau: CGFloat = 0.65

    static let resolverSwitchDwell: TimeInterval = 0.15

    static let zoomInTau: CGFloat = 0.2
    static let zoomOutTau: CGFloat = 0.25
    static let reducedMotionStableDelay: TimeInterval = 0.3

    static let exitHold: TimeInterval = 1.2
    static let minTurnEnter = 16.0
    static let turnPeakDefault = 33.0
    static let turnLearnMinEpisode: TimeInterval = 1.0
    static let turnLearnStep = 0.1
    static let turnLearnSessionCap = 6.0
    static let turnUnwantedStep = 2.0
    static let sideCorrectionWindow: TimeInterval = 6.0
    static let sideCorrectionAfterEnd: TimeInterval = 3.0
    static let handLearnSessionRange = 0.15
    static let headRearmEnabled = true
    static let headRearmStraight: TimeInterval = 0.3

    static let pitchEnabled = true
    static let pitchYawFreezeEnabled = true
    static let pitchHandSupportEnabled = true
    static let pitchNominalRatio = 0.6
    static let pitchNoseGain = 0.4
    static let pitchMaxYaw = 35.0
    static let pitchTau = 0.2
    static let pitchLiftEnter = 6.0
    static let pitchLiftExit = 3.0
    static let pitchLiftDwell: TimeInterval = 0.2
    static let pitchReleaseDwell: TimeInterval = 0.3
    static let pitchFreezeRate = 40.0
    static let pitchFreezeHold: TimeInterval = 0.35
    static let pitchLearnWindow = 8.0
    static let pitchBaselineTau = 6.0
    static let maxPitchBaseline = 10.0
    static let pitchLipsReach: CGFloat = 1.15
    static let pitchEyeDwellFactor: TimeInterval = 0.75

    static let toolTipReach: CGFloat = 0.3
    static let toolReachFist: CGFloat = 0.5
    static let toolFistMaxExt: CGFloat = 1.6
    static let gripCurlMax: CGFloat = 1.45
    static let gripStraightMin: CGFloat = 1.75
    static let gripMinCurled = 2
    static let gripThumbMax: CGFloat = 0.8
    static let gripEnterDwell: TimeInterval = 0.35
    static let eyeLipsGripDwell: TimeInterval = 0.35


    static let handMaxGap: TimeInterval = 0.5
    static let maxStep: TimeInterval = 0.35
    static let nominalStep: TimeInterval = 1.0 / 12.0

    static let lipsEnterDwell: TimeInterval = 0.35
    static let lipsReleaseDwell: TimeInterval = 0.4
    static let lipsPose2Max: CGFloat = 0.4
    static let lipMotionBaselineTau = 0.4
    static let lipMotionDevTau = 0.1
    static let lipMotionEnter = 0.05
    static let lipMotionExit = 0.04
    static let lipMotionLostGrace: TimeInterval = 0.5
    static let lipsStillDwell: TimeInterval = 0.2
    static let lipsTriggerStretchX: CGFloat = 1.1
    static let lipsTriggerStretchY: CGFloat = 0.7

    static let lipsLineOffset: CGFloat = 0
    static let lipsLineFallback: CGFloat = 0.5
    static let zoneLockScale: CGFloat = 1.15
    static let zoneLockMargin: CGFloat = 0.15
    static let zoneSwitchDwell: TimeInterval = 0.85
    static let eyeShapeInner: CGFloat = 0.8
    static let eyeShapeOuter: CGFloat = 1.1
    static let eyeShapeUp: CGFloat = 0.9
    static let eyeShapeDown: CGFloat = 1.0

    static let eyeTriggerRadiusX: CGFloat = 0.5
    static let eyeTriggerRadiusY: CGFloat = 0.4
    static let eyeZoneOffsetX: CGFloat = 0.12
    static let eyeFlowEnterDwell: TimeInterval = 0.35
    static let eyeFlowSwitchDwell: TimeInterval = zoneSwitchDwell
    static let eyeFlowReleaseDwell: TimeInterval = 0.4
    static let eyeActivityEnter = 0.15
    static let eyeActivityExit = 0.07
    static let eyeTurnWidthRatio = 0.6
    static let eyeActivitySustain: TimeInterval = 0.45
    static let eyeActivityClear: TimeInterval = 0.2
    static let eyeActivityTau = 0.1
    static let eyeBaselineTau = 6.0
    static let eyeActivityMaxYaw = 25.0
    static let eyeLearnMaxYaw = 15.0
    static let eyeUnknownCap: TimeInterval = 2.2
    static let eyeFlowPoseGrace: TimeInterval = 0.3
    static let eyeHoldUsesAllFingertips = true

    static let noseEnterDwell: TimeInterval = 0.35
    static let noseReleaseDwell: TimeInterval = 0.4
    static let noseColumnHalfWidth: CGFloat = 0.3
    static let noseColumnTop: CGFloat = 0.25
    static let maxTriggerScale: CGFloat = 1.1
    static let fingerPointEnabled = true
    static let toolEnterDwell: TimeInterval = 0.35
    static let fingerPointDwell: TimeInterval = 0.35
    static let nosePointDwell: TimeInterval = fingerPointDwell
    static let noseLostHoldCap: TimeInterval = 0.5
    static let toolSwitchDwell: TimeInterval = zoneSwitchDwell
    static let softHoldWindow: TimeInterval = 0.3
    static let fastReleaseDwell: TimeInterval = 0.15
    static let holdGrace: TimeInterval = 0.85
    static let reentryWindow: TimeInterval = 1.5
    static let reentryDwell: TimeInterval = 0.2

    static let pinInset: CGFloat = 0.12
    static let panSmoothTime: CGFloat = 0.18
    static let pinCenterPullX: CGFloat = 1.0
    static let focusMinCutoff: Double = 0.4
    static let focusBeta: Double = 0.06

    static let distGamma: Double = 1.0
    static let distMinFactor: Double = 0.1
    static let distMaxFactor: Double = 10.0
    static let distMaxScale: CGFloat = 30.0
    static let distMaxYaw: Double = 40.0
    static let distDeadBand: Double = 0.02
    static let distFilterMinCutoff: Double = 0.7
    static let distFilterBeta: Double = 3.0
    static let distBaselineSpan: Double = 0.4

    static let stabSampleRate: Double = 100.0
    static let stabMarginUse: Double = 0.95
    static let fusedPathTau: Double = 0.4

    static let handLowLightEnabled = true
    static let handDarkRelaxEnabled = true
    static let handSeenBoostsRate = true
    static let handLowLightTargetLuma = 0.18
    static let handLowLightMinEV = 0.6
    static let handLowLightMaxEV = 3.0
    static let handLowLightMeasureInterval: TimeInterval = 0.5
    static let handDarkEVThreshold = 1.0
    static let handDarkJointConfidence: Float = 0.15
    static let handDarkBaseConfidence: Float = 0.12

    static let handLostHoldCap: TimeInterval = 0.5
    static let handLostHoldEnabled = true

    static let poseKeepEnabled = true
    static let poseKeepMaxAge: TimeInterval = 0.6
    static let poseKeepRadius: CGFloat = 0.8
    static let poseKeepFactor: CGFloat = 1.3
    static let poseKeepJointConfidence: Float = 0.15
    static let poseKeepBaseConfidence: Float = 0.12
    static let gripCurlKeepMax: CGFloat = 1.6
    static let gripStraightKeepMin: CGFloat = 1.85
    static let gripThumbKeepMax: CGFloat = 1.0

    static let trackEnabled: Bool = true
    static let trackInvertX: Bool = false
    static let trackInvertY: Bool = false
}
