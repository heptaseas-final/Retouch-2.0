import CoreImage
import QuartzCore

nonisolated final class LowLightEnhancer: @unchecked Sendable {
    private let context = CIContext()
    private let lock = NSLock()
    private var smoothedEV = 0.0
    private var lastMeasure: CFTimeInterval = 0

    var currentEV: Double { lock.withLock { smoothedEV } }

    func enhance(_ image: CIImage) -> CIImage {
        let now = CACurrentMediaTime()
        let ev: Double = lock.withLock {
            if now - lastMeasure >= ZoomTuning.handLowLightMeasureInterval {
                lastMeasure = now
                let luma = max(centerLuma(of: image), 0.002)
                var target = log2(ZoomTuning.handLowLightTargetLuma / luma)
                target = min(max(target, 0), ZoomTuning.handLowLightMaxEV)
                if target < ZoomTuning.handLowLightMinEV { target = 0 }
                smoothedEV += 0.5 * (target - smoothedEV)
            }
            return smoothedEV
        }
        guard ev >= 0.05 else { return image }
        return image.applyingFilter("CIExposureAdjust", parameters: ["inputEV": ev])
    }

    private func centerLuma(of image: CIImage) -> Double {
        let e = image.extent
        guard e.width > 4, e.height > 4 else { return 1 }
        let crop = CGRect(x: e.minX + e.width * 0.15, y: e.minY + e.height * 0.15,
                          width: e.width * 0.7, height: e.height * 0.7)
        let avg = image.applyingFilter("CIAreaAverage",
                                       parameters: [kCIInputExtentKey: CIVector(cgRect: crop)])
        var px = [Float](repeating: 0, count: 4)
        context.render(avg, toBitmap: &px, rowBytes: 16,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBAf, colorSpace: nil)
        return Double(0.2126 * px[0] + 0.7152 * px[1] + 0.0722 * px[2])
    }
}
