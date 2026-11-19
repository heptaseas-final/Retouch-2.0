import Foundation
import CoreImage
import Vision

nonisolated struct DetectionSnapshot<Value> {
    let value: Value
    let sequence: Int
    let timestamp: Date
}

nonisolated struct RateGate {
    private var nextDue: TimeInterval = 0

    mutating func allow(now: TimeInterval, interval: TimeInterval) -> Bool {
        guard interval > 0 else { return true }
        if now < nextDue - 0.004 { return false }
        let next = nextDue + interval
        nextDue = next > now ? next : now + interval
        return true
    }
}

nonisolated struct DetectionPacer {
    private var lastMotion = Date()
    private var baseRate = ZoomTuning.detectionRate
    private var lastEnvCheck = Date.distantPast
    private var lastFrame: TimeInterval = 0
    private var frameInterval: TimeInterval = 1.0 / 30
    private var slowSince: TimeInterval?
    private var steadySince: TimeInterval?
    private var isStrained = false

    mutating func noteMotion(at now: Date) { lastMotion = now }

    mutating func noteFrame(at now: TimeInterval) {
        defer { lastFrame = now }
        let gap = now - lastFrame
        guard lastFrame > 0, gap < 0.5 else {
            frameInterval = 1.0 / 30
            slowSince = nil
            steadySince = nil
            return
        }
        frameInterval += (gap - frameInterval) * 0.1
        let fps = 1 / frameInterval
        if fps < ZoomTuning.strainFps {
            steadySince = nil
            let start = slowSince ?? now
            slowSince = start
            if now - start >= ZoomTuning.strainEnterAfter { isStrained = true }
        } else {
            slowSince = nil
            if fps >= ZoomTuning.strainRecoverFps {
                let start = steadySince ?? now
                steadySince = start
                if isStrained, now - start >= ZoomTuning.strainExitAfter { isStrained = false }
            } else {
                steadySince = nil
            }
        }
    }

    mutating func interval(now: Date) -> TimeInterval {
        if now.timeIntervalSince(lastEnvCheck) >= ZoomTuning.envCheckInterval {
            lastEnvCheck = now
            let info = ProcessInfo.processInfo
            switch info.thermalState {
            case .nominal: baseRate = ZoomTuning.detectionRate
            case .fair: baseRate = ZoomTuning.fairRate
            default: baseRate = ZoomTuning.seriousRate
            }
            if info.isLowPowerModeEnabled { baseRate = min(baseRate, ZoomTuning.seriousRate) }
        }
        var rate = baseRate
        if isStrained { rate = min(rate, ZoomTuning.fairRate) }
        if now.timeIntervalSince(lastMotion) >= ZoomTuning.idleAfter {
            rate = min(rate, ZoomTuning.idleRate)
        }
        return 1 / rate
    }
}

nonisolated enum AnalysisImage {
    static func handler(for pixelBuffer: CVPixelBuffer, enhancer: LowLightEnhancer? = nil) -> VNImageRequestHandler {
        let width = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let target = ZoomTuning.analysisWidth
        let needsScale = ZoomTuning.downscaleEnabled && width > target * 1.2
        guard needsScale || enhancer != nil else {
            return VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored)
        }
        var image = CIImage(cvPixelBuffer: pixelBuffer)
        if needsScale {
            image = image.applyingFilter(
                "CILanczosScaleTransform",
                parameters: [kCIInputScaleKey: target / width, kCIInputAspectRatioKey: 1.0]
            )
        }
        if let enhancer { image = enhancer.enhance(image) }
        return VNImageRequestHandler(ciImage: image, orientation: .leftMirrored)
    }
}
