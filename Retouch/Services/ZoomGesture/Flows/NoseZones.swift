import CoreGraphics

nonisolated struct NoseZones {
    var triggerScale: CGFloat = 1

    private let eyes: EyeZones
    private let noseOffset: CGFloat

    init?(points: FacePoints) {
        guard let nose = points.nose, let eyes = EyeZones(points: points) else { return nil }
        self.eyes = eyes
        self.noseOffset = eyes.s(nose)
    }

    func owns(_ p: CGPoint) -> Bool {
        inTrigger(p)
    }

    func inTrigger(_ p: CGPoint) -> Bool {
        inColumn(p, widthScale: triggerScale, hold: false)
    }

    func holds(_ p: CGPoint) -> Bool {
        inColumn(p, widthScale: triggerScale * ZoomTuning.noseHoldScale, hold: true)
    }

    private func inColumn(_ p: CGPoint, widthScale: CGFloat, hold: Bool) -> Bool {
        guard abs(eyes.s(p) - noseOffset) <= ZoomTuning.noseColumnHalfWidth * widthScale,
              eyes.t(p) >= ZoomTuning.noseColumnTop,
              eyes.isAboveLips(p, hold: hold) else { return false }
        return !eyes.inEyeTerritory(p, margin: hold ? 0 : ZoomTuning.zoneGap)
    }
}
