extension AnalyticsZoomMode {
    init(part: FacePart) {
        switch part {
        case .face: self = .auto
        case .leftEye: self = .lockLeftEye
        case .rightEye: self = .lockRightEye
        case .mouth: self = .lockMouth
        case .nose: self = .lockNose
        case .smile: self = .lockFullFace
        }
    }
}
