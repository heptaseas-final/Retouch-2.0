import CoreGraphics
import CoreImage
import CoreVideo
import Foundation
import Metal

final class FrameEnhancer {

    struct Parameters {
        var noise: Float = 0
        var spatial: Float = 0
        var chromaDenoise: Float = 0
        var edgeSharpen: Float = 0
        var coring: Float = 0.01
        var night: Float = 0

        var needsProcessing: Bool {
            spatial > 0.01 ||
            chromaDenoise > 0.01 ||
            edgeSharpen > 0.01 ||
            night > 0.01
        }
    }

    private struct EnhanceUniforms {
        var spatial: Float
        var noise: Float
        var chroma: Float
        var sharpen: Float
        var coring: Float
        var night: Float
        var hasHistory: Float
    }

    private static let historyMaxGap: TimeInterval = 0.2

    private let device: MTLDevice
    private let pipeline: MTLComputePipelineState
    private let textureCache: CVMetalTextureCache
    private let placeholder: MTLTexture

    private var size = (width: 0, height: 0)
    private var outputs: [MTLTexture] = []
    private var outputIndex = 0
    private var history: [MTLTexture] = []
    private var historyIndex = 0
    private var lastHistoryTime: TimeInterval = 0

    init?(device: MTLDevice) {
        let placeholderDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: 1,
            height: 1,
            mipmapped: false
        )
        placeholderDescriptor.usage = [.shaderRead, .shaderWrite]
        placeholderDescriptor.storageMode = .private

        guard
            let placeholder = device.makeTexture(descriptor: placeholderDescriptor),
            let library = try? device.makeLibrary(
                source: FrameEnhancerShaders.source,
                options: nil
            ),
            let function = library.makeFunction(name: "enhance"),
            let pipeline = try? device.makeComputePipelineState(
                function: function
            )
        else {
            return nil
        }

        var cache: CVMetalTextureCache?

        let status = CVMetalTextureCacheCreate(
            nil,
            nil,
            device,
            nil,
            &cache
        )

        guard status == kCVReturnSuccess, let cache else {
            return nil
        }

        self.device = device
        self.pipeline = pipeline
        self.textureCache = cache
        self.placeholder = placeholder
    }

    func encode(
        _ input: CVPixelBuffer,
        _ parameters: Parameters,
        colorSpace: CGColorSpace?,
        into commandBuffer: MTLCommandBuffer
    ) -> CIImage? {

        guard CVPixelBufferGetPixelFormatType(input) ==
                kCVPixelFormatType_32BGRA
        else {
            return nil
        }

        let width = CVPixelBufferGetWidth(input)
        let height = CVPixelBufferGetHeight(input)

        guard width > 0, height > 0 else {
            return nil
        }

        guard prepare(width: width, height: height) else {
            return nil
        }

        var cvTexture: CVMetalTexture?

        let status = CVMetalTextureCacheCreateTextureFromImage(
            nil,
            textureCache,
            input,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTexture
        )

        guard
            status == kCVReturnSuccess,
            let cvTexture,
            let inputTexture = CVMetalTextureGetTexture(cvTexture),
            outputs.count == 2,
            let encoder = commandBuffer.makeComputeCommandEncoder()
        else {
            return nil
        }

        commandBuffer.addCompletedHandler { _ in
            withExtendedLifetime(cvTexture) {}
        }

        let output = outputs[outputIndex]
        outputIndex = 1 - outputIndex

        var night: Float = parameters.night > 0.01 ? min(parameters.night, 1) : 0
        var historyIn = placeholder
        var historyOut = placeholder
        var hasHistory = false

        if night > 0 {
            if prepareHistory() {
                let now = ProcessInfo.processInfo.systemUptime
                hasHistory = now - lastHistoryTime < Self.historyMaxGap
                lastHistoryTime = now

                historyIn = history[historyIndex]
                historyOut = history[1 - historyIndex]
                historyIndex = 1 - historyIndex
            } else {
                night = 0
            }
        }

        var uniforms = EnhanceUniforms(
            spatial: min(max(parameters.spatial, 0), 1),
            noise: min(max(parameters.noise, 0), 1),
            chroma: min(max(parameters.chromaDenoise, 0), 1),
            sharpen: min(max(parameters.edgeSharpen, 0), 1),
            coring: max(parameters.coring, 0),
            night: night,
            hasHistory: hasHistory ? 1 : 0
        )

        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(output, index: 1)
        encoder.setTexture(historyIn, index: 2)
        encoder.setTexture(historyOut, index: 3)

        encoder.setBytes(
            &uniforms,
            length: MemoryLayout<EnhanceUniforms>.stride,
            index: 0
        )

        let threadgroupSize = MTLSize(
            width: 16,
            height: 16,
            depth: 1
        )

        let gridSize = MTLSize(
            width: width,
            height: height,
            depth: 1
        )

        encoder.dispatchThreads(
            gridSize,
            threadsPerThreadgroup: threadgroupSize
        )

        encoder.endEncoding()

        var options: [CIImageOption: Any] = [:]

        if let colorSpace {
            options[.colorSpace] = colorSpace
        }

        return CIImage(
            mtlTexture: output,
            options: options
        )?.oriented(.downMirrored)
    }

    private func makeDescriptor() -> MTLTextureDescriptor {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: size.width,
            height: size.height,
            mipmapped: false
        )

        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .private

        return descriptor
    }

    private func prepare(width: Int, height: Int) -> Bool {

        guard size.width != width || size.height != height else {
            return outputs.count == 2
        }

        size = (width: width, height: height)
        history.removeAll()
        historyIndex = 0
        lastHistoryTime = 0

        let descriptor = makeDescriptor()
        var newOutputs: [MTLTexture] = []

        for _ in 0..<2 {
            guard let texture = device.makeTexture(
                descriptor: descriptor
            ) else {
                outputs.removeAll()
                size = (width: 0, height: 0)
                return false
            }

            newOutputs.append(texture)
        }

        outputs = newOutputs
        outputIndex = 0

        return true
    }

    private func prepareHistory() -> Bool {

        guard history.count != 2 else {
            return true
        }

        let descriptor = makeDescriptor()
        var newHistory: [MTLTexture] = []

        for _ in 0..<2 {
            guard let texture = device.makeTexture(
                descriptor: descriptor
            ) else {
                history.removeAll()
                return false
            }

            newHistory.append(texture)
        }

        history = newHistory
        historyIndex = 0
        lastHistoryTime = 0

        return true
    }
}
