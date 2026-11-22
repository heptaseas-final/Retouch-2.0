import CoreGraphics
import CoreMedia
import Foundation

nonisolated enum RecordingConfig {
    static let maxDuration: TimeInterval = 15.0
    static let minDuration: TimeInterval = 1.0
    static let frameInterval: TimeInterval = 1.0 / 30.0
    static let frameIntervalTolerance = 0.9
    static let timescale: CMTimeScale = 600

    static let thumbnailLifetime: Duration = .seconds(10)
    static let noticeLifetime: Duration = .seconds(2)
    static let undoLifetime: Duration = .seconds(8)
    static let thumbnailPixelSize = CGSize(width: 240, height: 320)
    static let thumbnailSize = CGSize(width: 96, height: 128)
    static let thumbnailCornerRadius: CGFloat = 16
    static let thumbnailBorderWidth: CGFloat = 3
    static let durationShadowRadius: CGFloat = 2
    static let thumbnailSwipeDistance: CGFloat = 80
    static let thumbnailSwipeFade = 0.7
    static let thumbnailTapSlop: CGFloat = 10
    static let thumbnailDiscardDuration = 0.2
    static let recordingDotSize: CGFloat = 10
    static let previewCornerRadius: CGFloat = 24
    static let previewBorderWidth: CGFloat = 3
    static let closeButtonOffset = CGSize(width: 8, height: -18)
    static let fileTabSize = CGSize(width: 88, height: 22)
    static let fileTabInset: CGFloat = 10
    static let previewDimOpacity = 0.6
    static let previewStartScale: CGFloat = 0.2
    static let clipAspectRatio: CGFloat = 3.0 / 4.0
    static let minTapTarget: CGFloat = 44
    static let voiceOverFocusDelay: Duration = .milliseconds(300)
}
