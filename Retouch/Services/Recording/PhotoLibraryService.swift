import Foundation
import Photos

nonisolated enum PhotoSaveResult: Equatable, Sendable {
    case saved, denied, failed
}

nonisolated protocol PhotoLibraryServicing: Sendable {
    func saveVideo(at url: URL) async -> PhotoSaveResult
}

nonisolated final class PhotoLibraryService: PhotoLibraryServicing {
    func saveVideo(at url: URL) async -> PhotoSaveResult {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return .denied }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
            return .saved
        } catch {
            return .failed
        }
    }
}
