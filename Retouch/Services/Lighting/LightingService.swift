import Observation
import CoreGraphics

protocol LightingServicing: AnyObject {
    var selectedColor: LightColor { get }
    var filterColor: ManualColorChoice? { get }
    var ringLightLevel: Double { get }
    var closeness: Double { get }
    var isAutoBrightness: Bool { get }
    var brightness: Double { get }
    var config: LightingConfig { get }
    func setAuto(_ isOn: Bool)
    func setBrightness(_ value: Double)
    func select(_ color: LightColor)
    func setLightMode(_ mode: LightMode)
}

@Observable
final class LightingService: LightingServicing, CameraLifecycleListening {
    private(set) var selectedColor: LightColor = .white
    private(set) var appliedBrightness: Double = 0
    private(set) var manualBrightness: Double?
    private(set) var filterColor: ManualColorChoice?
    private(set) var ringLightLevel: Double = 0
    private(set) var closeness: Double = 0

    @ObservationIgnored let config: LightingConfig
    @ObservationIgnored private let brightnessController: BrightnessController
    @ObservationIgnored private let engine: LightingEngine
    @ObservationIgnored private var cameraState: CameraState = .idle
    @ObservationIgnored private var autoRingLight = 0.0
    @ObservationIgnored private var brightnessCap = 1.0
    @ObservationIgnored private var isStarted = false
    @ObservationIgnored private var isAppActive: Bool

    init(engine: LightingEngine, brightnessController: BrightnessController, isAppActive: Bool) {
        self.engine = engine
        self.config = engine.config
        self.brightnessController = brightnessController
        self.isAppActive = isAppActive
        appliedBrightness = Self.roundedPercent(brightnessController.current)

        brightnessController.onChange = { [weak self] value in
            guard let self else { return }
            let rounded = Self.roundedPercent(value)
            if rounded != appliedBrightness { appliedBrightness = rounded }
        }
        engine.onOutput = { [weak self] in self?.engineDidUpdate($0) }
        engine.onCloseness = { [weak self] in self?.closeness = $0 }
    }

    var isAutoBrightness: Bool { manualBrightness == nil }

    var brightness: Double { manualBrightness ?? appliedBrightness }

    func setAuto(_ isOn: Bool) {
        if isOn {
            selectedColor = .white
            resetToAuto()
        } else {
            setManualBrightness(appliedBrightness)
        }
    }

    func setBrightness(_ value: Double) {
        setManualBrightness(value)
    }

    func select(_ color: LightColor) {
        selectedColor = color
        filterColor = color.manualChoice
        engine.correction = LightingTuning.correction(for: color.manualChoice)
    }

    func setLightMode(_ mode: LightMode) {
        guard let color = mode.lightColor else {
            setAuto(true)
            return
        }
        select(color)
        setBrightness(1)
    }

    func cameraWillStart() {
        isStarted = true
        brightnessController.captureBaseline()
    }

    func cameraDidStop(isStarted: Bool) {
        self.isStarted = isStarted
        pauseAdjustments()
        brightnessController.restoreBaseline()
    }

    func appActiveDidChange(_ isActive: Bool, isStarted: Bool) {
        isAppActive = isActive
        self.isStarted = isStarted
        guard isStarted else { return }
        if isActive {
            applyBrightness()
        } else {
            brightnessController.restoreBaseline()
            ringLightLevel = 0
        }
    }

    func cameraStateDidChange(to state: CameraState, isStarted: Bool) {
        self.isStarted = isStarted
        let wasRunning = cameraState == .running
        cameraState = state
        if state == .running, !wasRunning {
            pauseAdjustments()
            applyBrightness()
        } else if state != .running, wasRunning {
            pauseAdjustments()
            if isStarted { brightnessController.ramp(to: brightnessController.baseline) }
        }
    }

    private func setManualBrightness(_ level: Double) {
        manualBrightness = min(max(level, 0), 1)
        applyBrightness()
    }

    private func resetToAuto() {
        manualBrightness = nil
        filterColor = nil
        engine.correction = LightingTuning.auto
        applyBrightness()
    }

    private func pauseAdjustments() {
        engine.reset()
        autoRingLight = 0
        ringLightLevel = 0
    }

    private func engineDidUpdate(_ output: LightingOutput) {
        guard isStarted, cameraState == .running else { return }
        autoRingLight = output.ringLight
        brightnessCap = output.screenBrightnessCap
        if manualBrightness == nil { applyAutoLight() }
    }

    private func applyBrightness() {
        guard isAppActive else { return }
        if let manualBrightness {
            brightnessController.set(manualBrightness)
            let baseline = Double(brightnessController.baseline)
            let level = baseline >= 0.98
                ? (manualBrightness >= 0.98 ? 1 : 0)
                : min(max((manualBrightness - baseline) / (1 - baseline), 0), 1)
            ringLightLevel = level
            engine.manualPanel = level
        } else {
            engine.manualPanel = nil
            applyAutoLight()
        }
    }

    private func applyAutoLight() {
        guard isAppActive else { return }
        if ringLightLevel != autoRingLight { ringLightLevel = autoRingLight }
        let baseline = Double(brightnessController.baseline)
        let pre = Double(max(config.panelPreRampFraction, 0.01))
        let t = min(max(autoRingLight / pre, 0), 1)
        let target = baseline + (1 - baseline) * t * t * (3 - 2 * t)
        brightnessController.ramp(to: CGFloat(min(target, max(baseline, brightnessCap))))
    }

    private static func roundedPercent(_ value: CGFloat) -> Double {
        (Double(value) * 100).rounded() / 100
    }
}

extension LightColor {
    var manualChoice: ManualColorChoice {
        switch self {
        case .white: .natural
        case .warm: .warm
        case .cool: .cool
        }
    }
}
