import Foundation
import Photos

enum PhotosService {
  static func save(_ data: Data) async throws {
    let authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    guard authorization == .authorized || authorization == .limited else {
      throw NSError(
        domain: "Privar", code: 2,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Photo access is denied or restricted. Enable Add Photos in Settings."
        ])
    }
    try await PHPhotoLibrary.shared().performChanges {
      PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
    }
  }
}
