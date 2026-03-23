import Foundation
import FirebaseStorage
import UIKit

enum StorageService {
    private static let storage = Storage.storage()

    /// Uploads raw image data to Firebase Storage and returns the download URL.
    static func uploadImage(data: Data, path: String) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let ref = storage.reference().child("\(path)/\(fileName)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    /// Uploads a UIImage (compressed to JPEG) and returns the download URL.
    static func uploadImage(_ image: UIImage, path: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.compressionFailed
        }
        return try await uploadImage(data: data, path: path)
    }

    /// Uploads multiple Data images concurrently, preserving order.
    static func uploadMultipleImages(images: [Data], path: String) async throws -> [String] {
        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (index, imageData) in images.enumerated() {
                group.addTask {
                    let url = try await uploadImage(data: imageData, path: path)
                    return (index, url)
                }
            }

            var results = [(Int, String)]()
            for try await result in group {
                results.append(result)
            }

            return results
                .sorted { $0.0 < $1.0 }
                .map { $0.1 }
        }
    }

    /// Uploads multiple UIImages concurrently, preserving order.
    static func uploadMultipleImages(_ images: [UIImage], path: String) async throws -> [String] {
        let dataArray = try images.map { image -> Data in
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                throw StorageError.compressionFailed
            }
            return data
        }
        return try await uploadMultipleImages(images: dataArray, path: path)
    }

    enum StorageError: LocalizedError {
        case compressionFailed

        var errorDescription: String? {
            switch self {
            case .compressionFailed:
                return "Failed to compress image"
            }
        }
    }
}
