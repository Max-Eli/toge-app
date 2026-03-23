import Foundation
import FirebaseFirestore

enum VideoService {
    private static let db = Firestore.firestore()

    static func getVideos() async throws -> [Video] {
        let snapshot = try await db.collection("videos")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Video.self) }
    }

    static func getVideos(category: String) async throws -> [Video] {
        let snapshot = try await db.collection("videos")
            .whereField("category", isEqualTo: category)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Video.self) }
    }

    static func incrementViews(videoId: String) async throws {
        try await db.collection("videos").document(videoId)
            .updateData(["views": FieldValue.increment(Int64(1))])
    }
}
