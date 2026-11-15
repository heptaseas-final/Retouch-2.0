import CoreGraphics
import Testing
@testable import Retouch

struct ToolCropRegionTests {
    private let imageSize = CGSize(width: 720, height: 1280)

    private func close(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) < 0.0001 && abs(a.minY - b.minY) < 0.0001
            && abs(a.width - b.width) < 0.0001 && abs(a.height - b.height) < 0.0001
    }

    @Test func cropsSquareAroundFaceCenter() throws {
        let region = try #require(ToolCropRegion(faceCenter: CGPoint(x: 0.5, y: 0.5), faceWidth: 0.4,
                                                 imageSize: imageSize, faceScale: 2))
        #expect(close(region.rect, CGRect(x: 72, y: 352, width: 576, height: 576)))
    }

    @Test func staysInsideImageNearEdges() throws {
        let region = try #require(ToolCropRegion(faceCenter: CGPoint(x: 0.02, y: 0.98), faceWidth: 0.4,
                                                 imageSize: imageSize, faceScale: 2))
        #expect(region.rect.minX == 0)
        #expect(region.rect.maxY == imageSize.height)
        #expect(region.rect.width == region.rect.height)
    }

    @Test func sideNeverPassesShortEdge() throws {
        let region = try #require(ToolCropRegion(faceCenter: CGPoint(x: 0.5, y: 0.5), faceWidth: 0.9,
                                                 imageSize: imageSize, faceScale: 2.2))
        #expect(region.rect.width == imageSize.width)
        #expect(region.rect.height == imageSize.width)
    }

    @Test func rejectsInvalidInput() {
        #expect(ToolCropRegion(faceCenter: .zero, faceWidth: 0, imageSize: imageSize, faceScale: 2) == nil)
        #expect(ToolCropRegion(faceCenter: .zero, faceWidth: 0.4, imageSize: .zero, faceScale: 2) == nil)
    }

    @Test func mapsCropBoxBackToFullFrame() throws {
        let region = try #require(ToolCropRegion(faceCenter: CGPoint(x: 0.5, y: 0.5), faceWidth: 0.4,
                                                 imageSize: imageSize, faceScale: 2))
        let mapped = region.toFullFrame(CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1))
        #expect(close(mapped, CGRect(x: 0.5, y: 0.5, width: 0.08, height: 0.045)))
    }

    @Test func wholeCropMapsToCropRectInFullFrame() throws {
        let region = try #require(ToolCropRegion(faceCenter: CGPoint(x: 0.5, y: 0.5), faceWidth: 0.4,
                                                 imageSize: imageSize, faceScale: 2))
        let mapped = region.toFullFrame(CGRect(x: 0, y: 0, width: 1, height: 1))
        #expect(close(mapped, CGRect(x: 0.1, y: 0.275, width: 0.8, height: 0.45)))
    }
}
