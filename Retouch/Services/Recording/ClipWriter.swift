import AVFoundation
import CoreImage
import Metal

nonisolated final class ClipWriter: @unchecked Sendable {
    enum AppendResult: Equatable {
        case idle, appended, skipped, reachedLimit
    }

    private struct Session {
        let writer: AVAssetWriter
        let input: AVAssetWriterInput
        let adaptor: AVAssetWriterInputPixelBufferAdaptor
        let url: URL
        let startTime: TimeInterval
        var lastTime: TimeInterval
    }

    private let lock = NSLock()
    private let context: CIContext
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    private var wantsRecording = false
    private var session: Session?

    init(commandQueue: MTLCommandQueue?) {
        context = commandQueue.map { CIContext(mtlCommandQueue: $0, options: [.cacheIntermediates: false]) }
            ?? CIContext(options: [.cacheIntermediates: false])
    }

    func begin() {
        lock.withLock { wantsRecording = true }
    }

    func append(_ frame: CIImage, time: TimeInterval) -> AppendResult {
        lock.lock()
        defer { lock.unlock() }
        guard wantsRecording else { return .idle }
        let image = Self.upright(frame)
        if session == nil { session = makeSession(size: image.extent.size, time: time) }
        guard var active = session else {
            wantsRecording = false
            return .idle
        }
        if time - active.startTime >= RecordingConfig.maxDuration {
            wantsRecording = false
            return .reachedLimit
        }
        let minGap = RecordingConfig.frameInterval * RecordingConfig.frameIntervalTolerance
        guard active.input.isReadyForMoreMediaData, time - active.lastTime >= minGap,
              let pool = active.adaptor.pixelBufferPool else { return .skipped }
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
        guard let buffer else { return .skipped }
        context.render(image, to: buffer, bounds: image.extent, colorSpace: colorSpace)
        let presentation = CMTime(seconds: time, preferredTimescale: RecordingConfig.timescale)
        guard active.adaptor.append(buffer, withPresentationTime: presentation) else { return .skipped }
        active.lastTime = time
        session = active
        return .appended
    }

    func finish() async -> RecordedClip? {
        guard let taken = takeSession() else { return nil }
        guard taken.lastTime.isFinite else {
            discard(taken)
            return nil
        }
        let end = taken.lastTime + RecordingConfig.frameInterval
        let duration = end - taken.startTime
        guard duration >= RecordingConfig.minDuration else {
            discard(taken)
            return nil
        }
        taken.input.markAsFinished()
        taken.writer.endSession(atSourceTime: CMTime(seconds: end, preferredTimescale: RecordingConfig.timescale))
        await taken.writer.finishWriting()
        guard taken.writer.status == .completed else {
            delete(taken.url)
            return nil
        }
        return RecordedClip(url: taken.url, duration: duration)
    }

    func cancel() {
        guard let taken = takeSession() else { return }
        discard(taken)
    }

    func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func takeSession() -> Session? {
        lock.withLock {
            wantsRecording = false
            let taken = session
            session = nil
            return taken
        }
    }

    private func discard(_ taken: Session) {
        taken.writer.cancelWriting()
        delete(taken.url)
    }

    private func makeSession(size: CGSize, time: TimeInterval) -> Session? {
        let url = FileManager.default.temporaryDirectory.appending(path: "clip-\(UUID().uuidString).mov")
        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mov) else { return nil }
        let width = Int(size.width)
        let height = Int(size.height)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.hevc,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
            ]
        ])
        input.expectsMediaDataInRealTime = true
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ])
        guard writer.canAdd(input) else { return nil }
        writer.add(input)
        guard writer.startWriting() else {
            delete(url)
            return nil
        }
        writer.startSession(atSourceTime: CMTime(seconds: time, preferredTimescale: RecordingConfig.timescale))
        return Session(writer: writer, input: input, adaptor: adaptor, url: url, startTime: time, lastTime: -.infinity)
    }

    private static func upright(_ frame: CIImage) -> CIImage {
        let oriented = frame.extent.width > frame.extent.height
            ? frame.oriented(.leftMirrored)
            : frame.oriented(.upMirrored)
        let extent = oriented.extent
        return oriented.transformed(by: CGAffineTransform(translationX: -extent.minX, y: -extent.minY))
    }
}
