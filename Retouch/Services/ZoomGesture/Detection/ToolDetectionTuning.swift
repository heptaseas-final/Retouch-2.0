import Foundation

nonisolated struct ToolDetectionTuning {
    static let modelName = "model_used"
    static let minConfidence: Float = 0.5
    static let triggerConfidence: Float = 0.7
    static let trackJumpDistance: CGFloat = 0.6
    static let trackMaxGap: TimeInterval = 0.5
    static let maxResultAge: TimeInterval = 0.5
    static let iouThreshold = 0.5
    static let cropFaceScale: CGFloat = 2.2
    static let tipElongated: CGFloat = 2.0
    static let tipMinPull: CGFloat = 0.2
    static let tipAmbiguity: CGFloat = 0.15
    static let faceAreaRadius: CGFloat = 0.75
    static let toolModeEnterStreak = 3
    static let toolModeExitAfter: TimeInterval = 1.5
    static let handMaxAge: TimeInterval = 0.6
    static let gripMargin: CGFloat = 0.1
    static let latchMatchRadius: CGFloat = 0.45
    static let latchOpenAfter: TimeInterval = 0.5
    static let latchHandLostAfter: TimeInterval = 1.0
    static let latchSafety: TimeInterval = 5.0
    static let poseToolPad: CGFloat = 0.05

    static let activeRate = 10.0
    static let probeRate = 4.0
    static let fairActiveRate = 6.0
    static let fairProbeRate = 2.0
    static let keepActiveAfterSeen: TimeInterval = 1.5
}
