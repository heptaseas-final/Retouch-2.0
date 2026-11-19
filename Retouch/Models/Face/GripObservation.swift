import CoreGraphics

nonisolated struct GripObservation {
    var grip: CGPoint
    var tip: CGPoint
    var twoFinger = false
    var threeFinger = false
    var holding = false
    var mode = ""
    var base: CGPoint?
    var kept = false
}

nonisolated struct PointObservation {
    var point: CGPoint
    var mode = ""
    var base: CGPoint?
}

nonisolated struct HandScan {
    var grips: [GripObservation] = []
    var points: [PointObservation] = []
    var fingertips: [CGPoint] = []
    var leadTips: [CGPoint] = []
    var handsSeen = 0
    var pinchRatio: CGFloat?
    var pinchRatio2: CGFloat?
    var confidence: Float = 0
}
