import Foundation

nonisolated struct ToolDetectionTuning {
    static let modelName = "model_used"
    static let minConfidence: Float = 0.35
    static let triggerConfidence: Float = 0.5
    static let trackJumpDistance: CGFloat = 0.6
    static let trackMaxGap: TimeInterval = 0.5
    static let maxResultAge: TimeInterval = 0.5
    static let iouThreshold = 0.5
    static let cropFaceScale: CGFloat = 2.2

    static let activeRate = 10.0
    static let probeRate = 4.0
    static let fairActiveRate = 6.0
    static let fairProbeRate = 2.0
    static let keepActiveAfterSeen: TimeInterval = 1.5
}
