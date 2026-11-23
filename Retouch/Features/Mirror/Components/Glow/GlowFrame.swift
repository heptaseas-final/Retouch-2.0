import SwiftUI

nonisolated enum GlowFrame {
    static let cameraAspect: CGFloat = 3.0 / 4.0
    static let sideLightWidth: CGFloat = 24
    static let holeCornerRadius: CGFloat = 24
    static let glowStartLevel = 0.02
    static let fullRiseDuration = 0.8
    static let fullFallDuration = 0.5
    static let minimumRampDuration = 0.25
    static let overallAnimation: Animation = .smooth(duration: 0.65)
    static let shrinksCameraWithGlow = false

    static func lightOpacity(level: Double) -> Double {
        min(max(level, 0), 1)
    }

    static func glowProgress(level: Double) -> CGFloat {
        let t = min(max((level - glowStartLevel) / (1 - glowStartLevel), 0), 1)
        return CGFloat(t * t * (3 - 2 * t))
    }

    static func rampDuration(from old: Double, to new: Double) -> Double {
        let start = lightOpacity(level: old)
        let end = lightOpacity(level: new)
        let span = (end > start ? fullRiseDuration : fullFallDuration) * abs(end - start)
        return max(span, minimumRampDuration)
    }

    static func windowRect(in size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0 else { return .zero }
        let isNarrow = size.width / size.height < cameraAspect
        let width = isNarrow ? size.width : size.height * cameraAspect
        let height = isNarrow ? size.width / cameraAspect : size.height
        return CGRect(x: (size.width - width) / 2, y: (size.height - height) / 2,
                      width: width, height: height)
    }

    static func zoomShrink(in size: CGSize, progress: CGFloat, isOverall: Bool) -> CGFloat {
        let full = fillScale(for: size)
        guard !isOverall, full > 0 else { return 1 }
        let fit = fillScale(for: windowRect(in: size).size) / full
        return 1 + (fit - 1) * min(max(progress, 0), 1)
    }

    static func previewShrink(in size: CGSize, progress: CGFloat, isOverall: Bool) -> CGFloat {
        guard shrinksCameraWithGlow else { return 1 }
        return zoomShrink(in: size, progress: progress, isOverall: isOverall)
    }

    static func windowedZoom(_ zoom: ZoomState, shrink: CGFloat) -> ZoomState {
        var result = zoom
        result.scale = zoom.scale * shrink
        result.offset = CGSize(width: zoom.offset.width * shrink, height: zoom.offset.height * shrink)
        if var fade = zoom.fade {
            fade.fromScale *= shrink
            fade.fromOffset = CGSize(width: fade.fromOffset.width * shrink, height: fade.fromOffset.height * shrink)
            result.fade = fade
        }
        return result
    }

    static func holeScale(in size: CGSize, progress: CGFloat, isOverall: Bool) -> CGSize {
        guard size.width > 0, size.height > 0 else { return CGSize(width: 1, height: 1) }
        let frame = windowRect(in: size).insetBy(dx: sideLightWidth, dy: 0)
        let t = isOverall ? 1 : min(max(progress, 0), 1)
        return CGSize(width: 1 + (frame.width / size.width - 1) * t,
                      height: 1 + (frame.height / size.height - 1) * t)
    }

    private static func fillScale(for size: CGSize) -> CGFloat {
        max(size.width / cameraAspect, size.height)
    }
}
