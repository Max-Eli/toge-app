import Foundation
import FirebaseFirestore
import UIKit

enum UserService {
    private static let db = Firestore.firestore()

    static func getUserProfile(uid: String) async throws -> UserProfile? {
        let doc = try await db.collection("users").document(uid).getDocument()
        return try? doc.data(as: UserProfile.self)
    }

    static func updateUserProfile(uid: String, data: [String: Any]) async throws {
        var updateData = data
        updateData["updatedAt"] = FieldValue.serverTimestamp()
        try await db.collection("users").document(uid).updateData(updateData)
    }

    static func uploadProfileImage(userId: String, imageData: Data) async throws -> String {
        return try await StorageService.uploadImage(data: imageData, path: "users/\(userId)/profile")
    }
}
