@testable import Retouch

@MainActor
final class FakeLightingService: LightingServicing {
    var selectedColor: LightColor = .white
    var filterColor: ManualColorChoice?
    var ringLightLevel: Double = 0
    var closeness: Double = 0
    var isAutoBrightness = true
    var brightness: Double = 0
    let config = LightingConfig()
    private(set) var autoCalls: [Bool] = []
    private(set) var lightModes: [LightMode] = []

    func setAuto(_ isOn: Bool) { autoCalls.append(isOn) }
    func setBrightness(_ value: Double) { brightness = value }
    func select(_ color: LightColor) { selectedColor = color }
    func setLightMode(_ mode: LightMode) { lightModes.append(mode) }
}
