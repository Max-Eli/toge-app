import Foundation
import FirebaseFirestore

enum PostService {
    private static let db = Firestore.firestore()

    static func getFeedPosts(limit count: Int = 20) async throws -> [Post] {
        let snapshot = try await db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: count)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            var post = try? doc.data(as: Post.self)
            return post
        }
    }

    static func createPost(
        authorId: String,
        authorName: String,
        authorAvatar: String,
        carName: String,
        content: String,
        images: [UIImage]
    ) async throws -> String {
        var imageURLs: [String] = []
        if !images.isEmpty {
            imageURLs = try await StorageService.uploadMultipleImages(images, path: "posts/\(authorId)")
        }

        let docRef = try await db.collection("posts").addDocument(data: [
            "authorId": authorId,
            "authorName": authorName,
            "authorAvatar": authorAvatar,
            "carName": carName,
            "content": content,
            "images": imageURLs,
            "likes": 0,
            "commentCount": 0,
            "createdAt": FieldValue.serverTimestamp(),
        ])
        return docRef.documentID
    }

    static func deletePost(_ postId: String) async throws {
        try await db.collection("posts").document(postId).delete()
    }

    static func toggleLike(postId: String, userId: String) async throws -> Bool {
        let likeRef = db.collection("posts").document(postId).collection("likes").document(userId)
        let snap = try await likeRef.getDocument()

        if snap.exists {
            try await likeRef.delete()
            try await db.collection("posts").document(postId).updateData([
                "likes": FieldValue.increment(Int64(-1))
            ])
            return false
        } else {
            try await likeRef.setData([
                "userId": userId,
                "createdAt": FieldValue.serverTimestamp(),
            ])
            try await db.collection("posts").document(postId).updateData([
                "likes": FieldValue.increment(Int64(1))
            ])
            return true
        }
    }

    static func hasUserLiked(postId: String, userId: String) async throws -> Bool {
        let snap = try await db.collection("posts").document(postId)
            .collection("likes").document(userId).getDocument()
        return snap.exists
    }

    static func getComments(postId: String) async throws -> [Comment] {
        let snapshot = try await db.collection("posts").document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Comment.self)
        }
    }

    static func addComment(
        postId: String,
        authorId: String,
        authorName: String,
        authorAvatar: String,
        content: String
    ) async throws -> String {
        let docRef = try await db.collection("posts").document(postId)
            .collection("comments").addDocument(data: [
                "postId": postId,
                "authorId": authorId,
                "authorName": authorName,
                "authorAvatar": authorAvatar,
                "content": content,
                "createdAt": FieldValue.serverTimestamp(),
            ])

        try await db.collection("posts").document(postId).updateData([
            "commentCount": FieldValue.increment(Int64(1))
        ])

        return docRef.documentID
    }
}
