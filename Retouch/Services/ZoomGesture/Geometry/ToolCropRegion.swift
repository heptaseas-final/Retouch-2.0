import CoreGraphics

nonisolated struct ToolCropRegion: Equatable {
    let rect: CGRect
    let imageSize: CGSize

    init?(faceCenter: CGPoint, faceWidth: CGFloat, imageSize: CGSize, faceScale: CGFloat) {
        guard imageSize.width > 0, imageSize.height > 0, faceWidth > 0, faceScale > 0 else { return nil }
        let side = min(faceWidth * imageSize.width * faceScale, min(imageSize.width, imageSize.height))
        let x = min(max(faceCenter.x * imageSize.width - side / 2, 0), imageSize.width - side)
        let y = min(max(faceCenter.y * imageSize.height - side / 2, 0), imageSize.height - side)
        rect = CGRect(x: x, y: y, width: side, height: side)
        self.imageSize = imageSize
    }

    func toFullFrame(_ box: CGRect) -> CGRect {
        CGRect(x: (rect.minX + box.minX * rect.width) / imageSize.width,
               y: (rect.minY + box.minY * rect.height) / imageSize.height,
               width: box.width * rect.width / imageSize.width,
               height: box.height * rect.height / imageSize.height)
    }
}
