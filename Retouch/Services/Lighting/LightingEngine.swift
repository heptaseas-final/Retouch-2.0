import AVFoundation
import Foundation

struct LightingOutput: Equatable {
    var ringLight: Double
    var screenBrightnessCap: Double
    var status = LightingStatus()
}

final class LightingEngine {
    let config: LightingConfig
    var onOutput: ((LightingOutput) -> Void)?
    var onCloseness: ((Double) -> Void)?

    private let camera: CameraSessionManager
    private let lock = NSLock()
    private var _manualPanel: Double?
    private var _redGain: Float = 1
    private var _blueGain: Float = 1
    private var baselineRedness: Float = 1.6
    private let rednessTolerance: Float = 1.05
    private let nearHeight: Float = 0.30
    private let closeHeight: Float = 0.60
    private let closeRedCut: Float = 0.17
    private let closeBlueBoost: Float = 0.13
    private let zoomStart: Float = 1.5
    private let zoomFull: Float = 4.0
    private var _zoomScale: Float = 1
    private var _correction = LightingTuning.auto
    private var _snapGains = false
    private var lastKnownLux: Float?
    private var _faceLux: Float?
    private let glowMaxMargin: Float = 0.03
    private let faceLuxPublishStep: Float = 0.1
    private let lowLuxFull: Float = 18
    private let lowLuxNone: Float = 30
    private let minRedGain: Float = 0.45
    private var _needsReset = true
    private var exposureRange: CameraExposureRange?
    private var lastTime: Double?
    private var smoothedLogLux: Float?
    private var panel: Float = 0
    private var isPanelOn = false
    private var quality = Quality.full
    private var published: LightingOutput?
    private var measuredFPS: Double = 0
    private let faceMeter = FaceLuxMeter()
    private var smoothedFaceLogLux: Float?
    private var smoothedRedness: Float?

    init(camera: CameraSessionManager, config: LightingConfig) {
        self.camera = camera
        self.config = config
        faceMeter.onResult = { [weak self] in self?.faceMeasured($0) }
    }

    var manualPanel: Double? {
        get { lock.withLock { _manualPanel } }
        set { lock.withLock { _manualPanel = newValue } }
    }

    var redGain: Float { lock.withLock { _redGain } }
    var blueGain: Float { lock.withLock { _blueGain } }
    var correction: LightingTuning.Correction {
        get { lock.withLock { _correction } }
        set { lock.withLock { _correction = newValue; _snapGains = true } }
    }
    var zoomScale: Float {
        get { lock.withLock { _zoomScale } }
        set { lock.withLock { _zoomScale = newValue } }
    }

    func reset() {
        lock.withLock { _needsReset = true }
    }

    func process(_ frame: CameraFrame) -> FrameEnhancer.Parameters {
        let (needsReset, manual) = lock.withLock { () -> (Bool, Double?) in
            defer { _needsReset = false }
            return (_needsReset, _manualPanel)
        }
        if needsReset { restart() }

        let dt = min(max(frame.time - (lastTime ?? frame.time - 1.0 / 60), 1.0 / 240), 0.25)
        lastTime = frame.time
        measuredFPS += (1 / dt - measuredFPS) * 0.1
        updateQuality(dt: dt)

        if exposureRange == nil { exposureRange = camera.exposureRange() }
        camera.setExposureBias(log2(Luma.decode(config.faceBrightness) / Luma.decode(0.5)))

        let roomLux = estimateRoomLux(frame, dt: Float(dt))
        if let aperture = exposureRange?.aperture {
            faceMeter.submit(buffer: frame.pixelBuffer, time: frame.time,
                             exposureDuration: frame.exposureDuration, iso: frame.iso, aperture: aperture)
        }
        let darkness = darkness(roomLux: roomLux, threshold: config.ringLightStartLux)
        updatePanel(roomLux: roomLux, manual: manual, dt: Float(dt))
        publish(LightingOutput(ringLight: Double(panel), screenBrightnessCap: quality.brightnessCap,
                               status: currentStatus()))

        let noise = noiseLevel(iso: frame.iso)
        var params = FrameEnhancer.Parameters()
        params.noise = noise
        params.chromaDenoise = darkness
        params.spatial = 0.6 * darkness
        params.edgeSharpen = 0.8 * quality.sharpen * darkness
        params.coring = 0.008 + 0.03 * noise
        if config.nightModeEnabled {
            let fpsScale = smoothstep(18, 23, Float(measuredFPS))
            params.night = smoothstep(0.1, 0.8, darkness) * config.nightStrength * fpsScale
            params.spatial *= 1 - 0.6 * params.night
        }
        return params
    }

    private func restart() {
        camera.setAutoExposure()
        camera.setAutoWhiteBalance()
        exposureRange = nil
        lastTime = nil
        smoothedLogLux = nil
        panel = 0
        isPanelOn = false
        published = nil
    }

    private func estimateRoomLux(_ frame: CameraFrame, dt: Float) -> Float? {
        guard let range = exposureRange, frame.exposureDuration > 0, frame.iso > 0 else { return nil }
        let offset = frame.exposureTargetOffset.isFinite ? min(max(frame.exposureTargetOffset, -4), 4) : 0
        let measured = config.luxCalibration * range.aperture * range.aperture
            / (Float(frame.exposureDuration) * frame.iso) * exp2(offset)
        let panelLight = 1 + (exp2(config.panelFullEV) - 1) * panel
        let logLux = log2(max(measured / panelLight, 0.1))
        let a = 1 - exp(-dt / 0.3)
        let smoothed = smoothedLogLux.map { $0 + (logLux - $0) * a } ?? logLux
        smoothedLogLux = smoothed
        return exp2(smoothed)
    }

    private func darkness(roomLux: Float?, threshold: Float) -> Float {
        guard let lux = roomLux else { return 0 }
        return min(max(log2(threshold / max(lux, 0.1)) / 1.5, 0), 1)
    }

    private func updatePanel(roomLux: Float?, manual: Double?, dt: Float) {
        if let manual {
            panel = Float(manual)
            return
        }
        let threshold = config.ringLightStartLux * (isPanelOn ? 1.25 : 1)
        let target = darkness(roomLux: roomLux, threshold: threshold) * quality.panelCap
        isPanelOn = target > 0.02
        let tau = Float(config.ringLightFadeTime) * (target > panel ? 1 : 2)
        panel += (target - panel) * (1 - exp(-dt / tau))
    }

    private func noiseLevel(iso: Float) -> Float {
        guard let range = exposureRange else { return 0 }
        let minISO = max(range.minISO, 1)
        let cap = max(range.maxISO * 0.5, minISO * 1.01)
        return min(max(log2(max(iso, minISO) / minISO) / log2(cap / minISO), 0), 1)
    }

    private func updateQuality(dt: TimeInterval) {
        let target = Quality.target(for: ProcessInfo.processInfo.thermalState)
        let a = Float(1 - exp(-dt / 2))
        quality.sharpen += (target.sharpen - quality.sharpen) * a
        quality.panelCap += (target.panelCap - quality.panelCap) * a
        quality.brightnessCap += (target.brightnessCap - quality.brightnessCap) * Double(a)
    }

    private func faceMeasured(_ result: FaceLuxMeter.Result) {
        updateRedness(result.redness, faceHeight: result.faceHeight)
        let accepted = result.areaLuma.compactMap { $0 }
        guard accepted.count >= config.minFaceAreas, result.exposureDuration > 0, result.iso > 0 else {
            smoothedFaceLogLux = nil
            lock.withLock { _faceLux = nil }
            return
        }
        let scale = config.faceLuxCalibration * result.aperture * result.aperture
            / (Float(result.exposureDuration) * result.iso) / config.skinReflectance
        let lux = scale * accepted.reduce(0, +) / Float(accepted.count)
        let logLux = log2(max(lux, 0.1))
        let smoothed = smoothedFaceLogLux.map { $0 + (logLux - $0) * 0.4 } ?? logLux
        smoothedFaceLogLux = smoothed
        lastKnownLux = exp2(smoothed)
        lock.withLock { _faceLux = exp2(smoothed) }
    }

    private func updateRedness(_ redness: Float?, faceHeight: Float?) {
        smoothedRedness = redness.map { new in smoothedRedness.map { $0 + (new - $0) * 0.4 } ?? new }
        updateColorGains(faceHeight: faceHeight)
    }

    private func updateColorGains(faceHeight: Float?) {
        let faceCloseness = faceHeight.map { smoothstep(nearHeight, closeHeight, $0) } ?? 1
        let zoomPart = smoothstep(zoomStart, zoomFull, zoomScale)
        let lowLight = lastKnownLux.map { 1 - smoothstep(lowLuxFull, lowLuxNone, $0) } ?? 0
        let closeness = max(zoomPart, faceCloseness * lowLight)
        let correction = self.correction
        let gate = max(zoomPart, lowLight) * correction.redness
        let reported = Double(closeness)
        DispatchQueue.main.async { [weak self] in self?.onCloseness?(reported) }
        if let r = smoothedRedness, closeness < 0.15 {
            baselineRedness = min(max(baselineRedness + (r - baselineRedness) * 0.05, 1.1), 2.2)
        }
        var redTarget: Float = 1
        if let r = smoothedRedness {
            let allowed = baselineRedness * rednessTolerance
            if r > allowed { redTarget = max(1 + (allowed / r - 1) * gate, minRedGain) }
        }
        redTarget *= 1 - closeRedCut * closeness * correction.redCut
        let blueTarget = 1 + closeBlueBoost * closeness * correction.blueBoost
        lock.withLock {
            if _snapGains {
                _redGain = redTarget
                _blueGain = blueTarget
                _snapGains = false
            } else {
                _redGain += (redTarget - _redGain) * (redTarget < _redGain ? 0.4 : 0.1)
                _blueGain += (blueTarget - _blueGain) * 0.15
            }
        }
    }

    private func currentStatus() -> LightingStatus {
        let thermal = ProcessInfo.processInfo.thermalState
        return LightingStatus(faceLux: lock.withLock { _faceLux }.map(Double.init),
                              isGlowAtMax: isPanelOn && panel >= quality.panelCap - glowMaxMargin,
                              isHeatLimited: thermal == .serious || thermal == .critical)
    }

    private func isSameStatus(_ a: LightingStatus, _ b: LightingStatus) -> Bool {
        guard a.isGlowAtMax == b.isGlowAtMax, a.isHeatLimited == b.isHeatLimited else { return false }
        switch (a.faceLux, b.faceLux) {
        case (nil, nil): return true
        case let (x?, y?): return abs(log2(max(x, 0.1) / max(y, 0.1))) < Double(faceLuxPublishStep)
        default: return false
        }
    }

    private func publish(_ output: LightingOutput) {
        if let published,
           abs(published.ringLight - output.ringLight) < 0.003,
           abs(published.screenBrightnessCap - output.screenBrightnessCap) < 0.01,
           isSameStatus(published.status, output.status) {
            return
        }
        published = output
        DispatchQueue.main.async { [weak self] in self?.onOutput?(output) }
    }

    private struct Quality {
        var sharpen: Float
        var panelCap: Float
        var brightnessCap: Double

        static let full = Quality(sharpen: 1, panelCap: 1, brightnessCap: 1)

        static func target(for state: ProcessInfo.ThermalState) -> Quality {
            switch state {
            case .nominal: .full
            case .fair: Quality(sharpen: 0, panelCap: 1, brightnessCap: 1)
            case .serious: Quality(sharpen: 0, panelCap: 0.7, brightnessCap: 0.6)
            case .critical: Quality(sharpen: 0, panelCap: 0.3, brightnessCap: 0.5)
            @unknown default: .full
            }
        }
    }
}
