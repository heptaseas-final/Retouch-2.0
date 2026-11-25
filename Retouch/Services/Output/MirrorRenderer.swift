import CoreImage
import CoreImage.CIFilterBuiltins
import Metal
import QuartzCore

final class MirrorRenderer {
    var zoom: ZoomState {
        get { lock.withLock { _zoom } }
        set { lock.withLock { _zoom = newValue } }
    }

    var isReady: Bool {
        lock.withLock { layer != nil && drawableSize.width > 0 && drawableSize.height > 0 }
    }

    private let device: MTLDevice?
    private let context: CIContext?
    private let makeupLook: MakeupLook?
    private let colorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
    private static let emptyColor = CIColor(red: 0xF5 / 255, green: 0xEC / 255, blue: 0xEF / 255, alpha: 1,
                                            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
        ?? CIColor(red: 0xF5 / 255, green: 0xEC / 255, blue: 0xEF / 255)

    private let lock = NSLock()
    private var layer: CAMetalLayer?
    private var drawableSize: CGSize = .zero
    private var pointScale: CGFloat = 1
    private var _zoom = ZoomState()

    init(device: MTLDevice?) {
        self.device = device
        makeupLook = device.flatMap { MakeupLook(device: $0) }
        context = device.map { [colorSpace] in
            CIContext(mtlDevice: $0, options: [.cacheIntermediates: false,
                                               .workingColorSpace: colorSpace,
                                               .outputColorSpace: colorSpace])
        }
    }

    func attach(_ layer: CAMetalLayer, drawableSize: CGSize) {
        layer.device = device
        layer.pixelFormat = .bgra8Unorm
        layer.framebufferOnly = false
        layer.maximumDrawableCount = 2
        layer.colorspace = colorSpace
        layer.drawableSize = drawableSize
        lock.withLock {
            self.layer = layer
            self.drawableSize = drawableSize
            self.pointScale = layer.contentsScale
        }
    }

    func detach(_ layer: CAMetalLayer) {
        lock.withLock {
            guard self.layer === layer else { return }
            self.layer = nil
            self.drawableSize = .zero
        }
    }

        func render(_ frame: CIImage, zoom: ZoomState, stabilization: CGSize = .zero, faceLock: FaceLockPose? = nil,
                    commandBuffer: MTLCommandBuffer) {
        let (layer, size, pointScale) = lock.withLock { (self.layer, drawableSize, self.pointScale) }
        guard let layer, let context, size.width > 0, size.height > 0 else {
            commandBuffer.commit()
            return
        }
        let isLandscape = frame.extent.width > frame.extent.height
        let upright = Self.uprightMirror(frame)
        let shake = Self.uprightFraction(stabilization, isLandscape: isLandscape)
        var image = compose(upright, size: size, zoom: zoom, pointScale: pointScale, stabilization: shake,
                            faceLock: faceLock)
        if let fade = zoom.fade {
            let previous = compose(upright, size: size,
                                   zoom: ZoomState(scale: fade.fromScale, offset: fade.fromOffset),
                                   pointScale: pointScale, stabilization: shake, faceLock: faceLock)
            let dissolve = CIFilter.dissolveTransition()
            dissolve.inputImage = previous
            dissolve.targetImage = image
            dissolve.time = Float(fade.progress)
            image = dissolve.outputImage?.cropped(to: CGRect(origin: .zero, size: size)) ?? image
        }

        if let makeupLook,
           ProcessInfo.processInfo.thermalState.rawValue < ProcessInfo.ThermalState.serious.rawValue,
           let target = makeupLook.nextTarget(width: Int(size.width), height: Int(size.height)) {
            let destination = CIRenderDestination(mtlTexture: target, commandBuffer: commandBuffer)
            destination.isFlipped = true
            destination.colorSpace = colorSpace
            _ = try? context.startTask(toRender: image, to: destination)
            guard let drawable = layer.nextDrawable(),
                  makeupLook.encode(source: target, into: drawable.texture,
                                    zoom: Float(zoom.scale), commandBuffer: commandBuffer) else {
                commandBuffer.commit()
                return
            }
            commandBuffer.present(drawable)
            commandBuffer.commit()
            return
        }

        guard let drawable = layer.nextDrawable() else {
            commandBuffer.commit()
            return
        }
        let destination = CIRenderDestination(mtlTexture: drawable.texture, commandBuffer: commandBuffer)
        destination.isFlipped = true
        destination.colorSpace = colorSpace
        _ = try? context.startTask(toRender: image, to: destination)
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    static func lockedPlacement(_ pose: FaceLockPose, extent: CGRect, fill: CGFloat,
                                size: CGSize) -> (origin: CGPoint, total: CGFloat) {
        let anchorTotal = fill * pose.anchorScale
        let total = fill * pose.scale
        let roomX = max(0.5 * (1 - size.width / (extent.width * anchorTotal)), 0)
        let roomY = max(0.5 * (1 - size.height / (extent.height * anchorTotal)), 0)
        let target = ZoomTuning.faceLockCentersFully ? pose.anchor
            : CGPoint(x: pose.entry.x + limited(pose.anchor.x - pose.entry.x,
                                                roomX * ZoomTuning.faceLockCenterRoomUseX),
                      y: pose.entry.y + limited(pose.anchor.y - pose.entry.y,
                                                roomY * ZoomTuning.faceLockCenterRoomUseY))
        let anchor = CGPoint(x: size.width / 2 + (target.x - 0.5) * extent.width * anchorTotal,
                             y: size.height / 2 + (target.y - 0.5) * extent.height * anchorTotal)
        let origin = CGPoint(x: anchor.x - (pose.face.x - 0.5) * extent.width * total,
                             y: anchor.y - (pose.face.y - 0.5) * extent.height * total)
        return (origin, total)
    }

    private static func uprightFraction(_ fraction: CGSize, isLandscape: Bool) -> CGSize {
        isLandscape ? CGSize(width: fraction.height, height: fraction.width)
                    : CGSize(width: -fraction.width, height: fraction.height)
    }

    private static func uprightMirror(_ frame: CIImage) -> CIImage {
        guard frame.extent.width > frame.extent.height else { return frame.oriented(.upMirrored) }
        return frame.oriented(.leftMirrored)
    }

    private func compose(_ frame: CIImage, size: CGSize, zoom: ZoomState, pointScale: CGFloat,
                         stabilization: CGSize, faceLock: FaceLockPose?) -> CIImage {
        let extent = frame.extent
        let outputRect = CGRect(origin: .zero, size: size)
        let empty = CIImage(color: Self.emptyColor).cropped(to: outputRect)

        let fill = max(size.width / extent.width, size.height / extent.height)
        let total = fill * max(zoom.scale, 0.01)

        let fast = CGSize(width: stabilization.width * extent.width * total,
                          height: stabilization.height * extent.height * total)
        let wanted = CGPoint(x: size.width / 2 + zoom.offset.width * pointScale + fast.width,
                             y: size.height / 2 - zoom.offset.height * pointScale - fast.height)
        let origin = Self.keptInsideFrame(wanted, extent: extent, total: total, size: size)
        if let faceLock, faceLock.weight > 0 {
            let placement = Self.lockedTransform(faceLock, extent: extent, fill: fill, size: size,
                                                 normalOrigin: origin, normalTotal: total)
            return Self.composeLocked(frame, placement: placement, size: size, empty: empty)
        }

        let center = CGPoint(x: extent.midX, y: extent.midY)

        let visible = CGRect(x: center.x - origin.x / total, y: center.y - origin.y / total,
                             width: size.width / total, height: size.height / total)
        let source = visible.insetBy(dx: -4, dy: -4).intersection(extent)
        guard !source.isNull, !source.isEmpty else { return empty }

        var image = frame.cropped(to: source)
            .transformed(by: CGAffineTransform(translationX: -source.minX, y: -source.minY))
        if total < 0.99 {
            let lanczos = CIFilter.lanczosScaleTransform()
            lanczos.inputImage = image
            lanczos.scale = Float(total)
            lanczos.aspectRatio = 1
            image = lanczos.outputImage ?? image.transformed(by: CGAffineTransform(scaleX: total, y: total))
        } else if total > 1.01 {
            image = image.transformed(by: CGAffineTransform(scaleX: total, y: total))
        }

        let placed = CGPoint(x: (source.minX - center.x) * total + origin.x,
                             y: (source.minY - center.y) * total + origin.y)
        return image.transformed(by: CGAffineTransform(translationX: placed.x, y: placed.y))
            .composited(over: empty)
            .cropped(to: outputRect)
    }

    static func lockedTransform(_ pose: FaceLockPose, extent: CGRect, fill: CGFloat, size: CGSize,
                                normalOrigin: CGPoint, normalTotal: CGFloat)
        -> (transform: CGAffineTransform, scale: CGFloat) {
        let w = min(max(pose.weight, 0), 1)
        let locked = lockedPlacement(pose, extent: extent, fill: fill, size: size)
        let face = CGPoint(x: extent.minX + pose.face.x * extent.width, y: extent.minY + pose.face.y * extent.height)
        let center = CGPoint(x: extent.midX, y: extent.midY)
        let normal = CGPoint(x: (face.x - center.x) * normalTotal + normalOrigin.x,
                             y: (face.y - center.y) * normalTotal + normalOrigin.y)
        let held = CGPoint(x: (face.x - center.x) * locked.total + locked.origin.x,
                           y: (face.y - center.y) * locked.total + locked.origin.y)
        let at = CGPoint(x: normal.x + (held.x - normal.x) * w, y: normal.y + (held.y - normal.y) * w)
        let scale = normalTotal + (locked.total - normalTotal) * w
        let angle = ZoomTuning.faceLockFollowsRoll ? -pose.roll * w : 0
        let transform = CGAffineTransform(translationX: -face.x, y: -face.y)
            .concatenating(CGAffineTransform(scaleX: scale, y: scale))
            .concatenating(CGAffineTransform(rotationAngle: angle))
            .concatenating(CGAffineTransform(translationX: at.x, y: at.y))
        return (transform, scale)
    }

    static func needsFill(_ transform: CGAffineTransform, extent: CGRect, scale: CGFloat, size: CGSize) -> Bool {
        let feather = size.width * ZoomTuning.faceLockFillFeather / max(scale, 0.0001)
        let inner = extent.insetBy(dx: feather, dy: feather)
        let inverse = transform.inverted()
        let corners = [CGPoint.zero, CGPoint(x: size.width, y: 0),
                       CGPoint(x: 0, y: size.height), CGPoint(x: size.width, y: size.height)]
        return !corners.allSatisfy { inner.contains($0.applying(inverse)) }
    }

    private static func composeLocked(_ frame: CIImage, placement: (transform: CGAffineTransform, scale: CGFloat),
                                      size: CGSize, empty: CIImage) -> CIImage {
        let outputRect = CGRect(origin: .zero, size: size)
        let front = frame.transformed(by: placement.transform)
        guard needsFill(placement.transform, extent: frame.extent, scale: placement.scale, size: size) else {
            return front.composited(over: empty).cropped(to: outputRect)
        }
        return seamless(frame, front: front, placement: placement, size: size)
    }

    private static func limited(_ value: CGFloat, _ limit: CGFloat) -> CGFloat {
        min(max(value, -limit), limit)
    }

    private static func seamless(_ frame: CIImage, front: CIImage,
                                 placement: (transform: CGAffineTransform, scale: CGFloat), size: CGSize) -> CIImage {
        let outputRect = CGRect(origin: .zero, size: size)
        let shrink = ZoomTuning.faceLockFillScale
        let down = CGAffineTransform(scaleX: shrink, y: shrink)
        let up = CGAffineTransform(scaleX: 1 / shrink, y: 1 / shrink)
        let feather = size.width * ZoomTuning.faceLockFillFeather
        let inset = feather / max(placement.scale, 0.0001)
        let backdrop = frame.clampedToExtent()
            .transformed(by: placement.transform)
            .transformed(by: down)
            .applyingGaussianBlur(sigma: Double(size.width * ZoomTuning.faceLockFillBlur * shrink))
            .transformed(by: up)
            .cropped(to: outputRect)
        let mask = CIImage(color: .white)
            .cropped(to: frame.extent.insetBy(dx: inset, dy: inset))
            .transformed(by: placement.transform)
            .transformed(by: down)
            .applyingGaussianBlur(sigma: Double(feather * shrink / 2))
            .transformed(by: up)
            .cropped(to: outputRect)
        return front.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: backdrop,
            kCIInputMaskImageKey: mask
        ]).cropped(to: outputRect)
    }

    private static func keptInsideFrame(_ origin: CGPoint, extent: CGRect, total: CGFloat, size: CGSize) -> CGPoint {
        CGPoint(x: clamp(origin.x, halfSpan: extent.width * total / 2, length: size.width),
                y: clamp(origin.y, halfSpan: extent.height * total / 2, length: size.height))
    }

    private static func clamp(_ value: CGFloat, halfSpan: CGFloat, length: CGFloat) -> CGFloat {
        let low = length - halfSpan, high = halfSpan
        guard low <= high else { return value }
        return min(max(value, low), high)
    }
}
