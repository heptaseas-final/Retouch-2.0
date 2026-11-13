import CoreGraphics
import CoreVideo
@testable import Retouch

final class FakeZoomService: ZoomServicing, @unchecked Sendable {
    var onZoomChange: (@Sendable (ZoomState) -> Void)?
    var onTracking: (@Sendable (ZoomTracking) -> Void)?
    private(set) var selectedParts: [FacePart] = []
    private(set) var resetCount = 0
    private(set) var stopCount = 0
    private(set) var gestureEnabled: [Bool] = []
    private(set) var reduceMotionValues: [Bool] = []

    func start() {}
    func stop() { stopCount += 1 }
    func setViewSize(_ size: CGSize) {}
    func process(_ pixelBuffer: CVPixelBuffer) {}
    func setGestureEnabled(_ isEnabled: Bool) { gestureEnabled.append(isEnabled) }
    func setManualTarget(_ target: ZoomTarget) {}
    func pinchChanged(_ magnification: CGFloat) {}
    func pinchEnded() {}
    func resetSession() { resetCount += 1 }
    func select(_ part: FacePart) { selectedParts.append(part) }
    func setReduceMotion(_ isOn: Bool) { reduceMotionValues.append(isOn) }
}
