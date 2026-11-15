import CoreImage
import CoreML
import QuartzCore
import Vision

nonisolated struct ToolDetection: Equatable, Sendable {
    enum Label: String, Sendable { case eye, lip, brush }

    let label: Label
    let confidence: Float
    let box: CGRect
}

nonisolated struct ToolScan: Sendable {
    var detections: [ToolDetection] = []
}

nonisolated final class MakeupToolDetector: @unchecked Sendable {
    private let request: VNCoreMLRequest?
    private let lock = NSLock()
    private var busy = false
    private var gate = RateGate()
    private var cache = ToolScan()
    private var cacheTime = Date.distantPast
    private var sequence = 0
    private var generation = 0

    init() {
        request = Self.makeRequest()
    }

    var isAvailable: Bool { request != nil }

    var snapshot: DetectionSnapshot<ToolScan> {
        lock.withLock { DetectionSnapshot(value: cache, sequence: sequence, timestamp: cacheTime) }
    }

    func submit(_ pixelBuffer: CVPixelBuffer, face: FaceObservation?, minInterval: TimeInterval) {
        guard request != nil, let face else { return }
        let mediaNow = CACurrentMediaTime()
        let gen = lock.withLock { () -> Int? in
            if busy || !gate.allow(now: mediaNow, interval: minInterval) { return nil }
            busy = true
            return generation
        }
        guard let gen else { return }

        let stamp = Date()
        nonisolated(unsafe) let buffer = pixelBuffer
        Task.detached(priority: .utility) { [self] in
            let scan = detect(buffer, face: face)
            lock.withLock {
                if gen == generation {
                    cache = scan
                    cacheTime = stamp
                    sequence += 1
                }
                busy = false
            }
        }
    }

    func reset() {
        lock.withLock {
            cache = ToolScan()
            generation += 1
        }
    }

    private func detect(_ pixelBuffer: CVPixelBuffer, face: FaceObservation) -> ToolScan {
        guard let request else { return ToolScan() }
        let oriented = CIImage(cvPixelBuffer: pixelBuffer).oriented(.leftMirrored)
        let extent = oriented.extent
        guard let region = ToolCropRegion(faceCenter: face.center, faceWidth: face.width,
                                          imageSize: extent.size,
                                          faceScale: ToolDetectionTuning.cropFaceScale) else { return ToolScan() }
        let cropRect = region.rect.offsetBy(dx: extent.minX, dy: extent.minY)
        let cropped = oriented
            .cropped(to: cropRect)
            .transformed(by: CGAffineTransform(translationX: -cropRect.minX, y: -cropRect.minY))

        let handler = VNImageRequestHandler(ciImage: cropped, orientation: .up)
        guard (try? handler.perform([request])) != nil,
              let results = request.results as? [VNRecognizedObjectObservation] else { return ToolScan() }

        var scan = ToolScan()
        for observation in results {
            guard let top = observation.labels.first,
                  let label = ToolDetection.Label(rawValue: top.identifier),
                  top.confidence >= ToolDetectionTuning.minConfidence else { continue }
            scan.detections.append(ToolDetection(label: label, confidence: top.confidence,
                                                 box: region.toFullFrame(observation.boundingBox)))
        }
        return scan
    }

    private static func makeRequest() -> VNCoreMLRequest? {
        guard let url = Bundle.main.url(forResource: ToolDetectionTuning.modelName, withExtension: "mlmodelc") else {
            return nil
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndNeuralEngine
        guard let model = try? MLModel(contentsOf: url, configuration: configuration),
              let visionModel = try? VNCoreMLModel(for: model) else { return nil }
        visionModel.featureProvider = try? MLDictionaryFeatureProvider(dictionary: [
            "confidenceThreshold": Double(ToolDetectionTuning.minConfidence),
            "iouThreshold": ToolDetectionTuning.iouThreshold
        ])
        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFill
        return request
    }
}
