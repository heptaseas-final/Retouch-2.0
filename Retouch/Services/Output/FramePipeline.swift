import CoreImage
import CoreVideo
import Metal
import VideoToolbox

final class FramePipeline {
    let renderer: MirrorRenderer
    let vision = FrameForwarder()

    private let lighting: LightingEngine
    private let enhancer: FrameEnhancer?
    private let queue: MTLCommandQueue?
    private let fallbackColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    private let visionScaler = VisionDownscaler(width: 1280)
    private let stabilizer = FusedStabilizer()

    init(lighting: LightingEngine) {
        let device = MTLCreateSystemDefaultDevice()
        self.lighting = lighting
        renderer = MirrorRenderer(device: device)
        queue = device?.makeCommandQueue()
        enhancer = device.flatMap { FrameEnhancer(device: $0) }
    }

    func process(_ frame: CameraFrame) {
        let scaled = visionScaler.scale(frame.pixelBuffer) ?? frame.pixelBuffer
        vision.send(scaled)

        var parameters = lighting.process(frame)

        guard renderer.isReady, let queue, let commandBuffer = queue.makeCommandBuffer() else { return }
        let zoom = renderer.zoom
        lighting.zoomScale = Float(zoom.scale)
        parameters.addZoomDenoise(scale: Float(zoom.scale))
        let source = CIImage(cvPixelBuffer: frame.pixelBuffer)
        let colorSpace = source.colorSpace ?? fallbackColorSpace
        let enhanced = parameters.needsProcessing
            ? enhancer?.encode(frame.pixelBuffer, parameters, colorSpace: colorSpace, into: commandBuffer)
            : nil

        var output = enhanced ?? source
        let redGain = lighting.redGain
        let blueGain = lighting.blueGain
        if redGain < 0.995 || blueGain > 1.005 {
            output = output.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: CGFloat(redGain), y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: CGFloat(blueGain), w: 0)
            ])
        }

        let stabilize = ZoomTuning.trackEnabled && zoom.scale > 1.001
        let shake = stabilizer.update(scaled, time: frame.time, scale: Double(zoom.scale), active: stabilize)
        renderer.render(output, zoom: zoom, stabilization: shake, commandBuffer: commandBuffer)
    }
}

private extension FrameEnhancer.Parameters {
    mutating func addZoomDenoise(scale: Float) {
        let zoom = smoothstep(1.3, 2.5, scale)
        guard zoom > 0.01 else { return }
        spatial = max(spatial, zoom * (0.3 + 0.3 * smoothstep(0.1, 0.6, noise)))
        edgeSharpen = max(edgeSharpen, 0.3 * zoom)
        coring = max(coring, 0.02)
    }
}

private final class VisionDownscaler {
    private let width: Int
    private var session: VTPixelTransferSession?
    private var pool: CVPixelBufferPool?
    private var poolSize = (width: 0, height: 0)

    init(width: Int) {
        self.width = width
        VTPixelTransferSessionCreate(allocator: nil, pixelTransferSessionOut: &session)
    }

    func scale(_ source: CVPixelBuffer) -> CVPixelBuffer? {
        let sourceWidth = CVPixelBufferGetWidth(source)
        let sourceHeight = CVPixelBufferGetHeight(source)
        guard let session, sourceWidth > width else { return nil }
        let height = (sourceHeight * width / sourceWidth) & ~1
        if poolSize.width != width || poolSize.height != height {
            let attributes: [CFString: Any] = [
                kCVPixelBufferPixelFormatTypeKey: CVPixelBufferGetPixelFormatType(source),
                kCVPixelBufferWidthKey: width,
                kCVPixelBufferHeightKey: height,
                kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
            ]
            pool = nil
            CVPixelBufferPoolCreate(nil, nil, attributes as CFDictionary, &pool)
            poolSize = (width, height)
        }
        var output: CVPixelBuffer?
        guard let pool, CVPixelBufferPoolCreatePixelBuffer(nil, pool, &output) == kCVReturnSuccess,
              let output,
              VTPixelTransferSessionTransferImage(session, from: source, to: output) == noErr else { return nil }
        return output
    }
}
