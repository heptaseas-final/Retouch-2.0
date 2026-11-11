import CoreGraphics
import Foundation

enum LightingTuning {
    static let softBlue: UInt32 = 0xC9DDFF
    static let autoShiftFullScale: CGFloat = 5
    static let autoShiftStrength = 1.0

    struct Correction {
        var redness: Float
        var redCut: Float
        var blueBoost: Float
    }

    static let auto = Correction(redness: 0.8, redCut: 0.8, blueBoost: 0.4)

    static func correction(for choice: ManualColorChoice?) -> Correction {
        switch choice {
        case nil: auto
        case .natural: auto
        case .warm: Correction(redness: 1, redCut: 1, blueBoost: 1.5)
        case .cool: Correction(redness: 1, redCut: 1, blueBoost: 0.3)
        }
    }

    static func blend(_ from: UInt32, _ to: UInt32, _ t: Double) -> (r: Double, g: Double, b: Double) {
        func mix(_ shift: UInt32) -> Double {
            let a = Double((from >> shift) & 0xFF)
            let b = Double((to >> shift) & 0xFF)
            return (a + (b - a) * t) / 255
        }
        return (mix(16), mix(8), mix(0))
    }
}
