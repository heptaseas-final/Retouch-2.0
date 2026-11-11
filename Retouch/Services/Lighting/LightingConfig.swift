import Foundation

struct LightingConfig {
    var autoFrameRateInDark: Bool = true
    var nightModeEnabled: Bool = true
    var nightStrength: Float = 0.6
    var skinReflectance: Float = 0.35
    var faceBrightness: Float = 0.50
    var ringLightStartLux: Float = 50
    var ringLightWidth: Float = 0.08
    var ringLightSoftness: Double = 0.5
    var ringLightFadeTime: TimeInterval = 0.25

    let panelPreRampFraction: Float = 0.5
    let luxCalibration: Float = 250
    let faceLuxCalibration: Float = 218
    let minFaceAreas: Int = 3
    let panelFullEV: Float = 1.0
}

enum Luma {
    static func decode(_ v: Float) -> Float {
        v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }
}

func smoothstep(_ e0: Float, _ e1: Float, _ x: Float) -> Float {
    let t = min(max((x - e0) / (e1 - e0), 0), 1)
    return t * t * (3 - 2 * t)
}
