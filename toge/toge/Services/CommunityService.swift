import Foundation
import FirebaseFirestore

final class CommunityService {
    static let shared = CommunityService()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Communities

    func getCommunities() async throws -> [Community] {
        let snap = try await db.collection("communities")
            .order(by: "memberCount", descending: true)
            .getDocuments()
        return snap.documents.compactMap { try? $0.data(as: Community.self) }
    }

    func getCommunity(id: String) async throws -> Community? {
        let doc = try await db.collection("communities").document(id).getDocument()
        return try? doc.data(as: Community.self)
    }

    func createCommunity(name: String, description: String, type: Community.CommunityType, category: String, ownerId: String, ownerName: String, rules: [String]) async throws -> String {
        let data: [String: Any] = [
            "name": name,
            "description": description,
            "type": type.rawValue,
            "category": category,
            "ownerId": ownerId,
            "ownerName": ownerName,
            "bannerURL": "",
            "avatarURL": "",
            "memberCount": 1,
            "postCount": 0,
            "rules": rules,
            "createdAt": FieldValue.serverTimestamp()
        ]

        let ref = try await db.collection("communities").addDocument(data: data)

        // Add owner as first member
        try await db.collection("communities").document(ref.documentID)
            .collection("members").document(ownerId).setData([
                "userId": ownerId,
                "role": "owner",
                "joinedAt": FieldValue.serverTimestamp()
            ])

        return ref.documentID
    }

    // MARK: - Membership

    func joinCommunity(communityId: String, userId: String) async throws {
        try await db.collection("communities").document(communityId)
            .collection("members").document(userId).setData([
                "userId": userId,
                "role": "member",
                "joinedAt": FieldValue.serverTimestamp()
            ])
        try await db.collection("communities").document(communityId).updateData([
            "memberCount": FieldValue.increment(Int64(1))
        ])
    }

    func leaveCommunity(communityId: String, userId: String) async throws {
        try await db.collection("communities").document(communityId)
            .collection("members").document(userId).delete()
        try await db.collection("communities").document(communityId).updateData([
            "memberCount": FieldValue.increment(Int64(-1))
        ])
    }

    func isMember(communityId: String, userId: String) async throws -> Bool {
        let doc = try await db.collection("communities").document(communityId)
            .collection("members").document(userId).getDocument()
        return doc.exists
    }

    // MARK: - Posts

    func getPosts(communityId: String) async throws -> [CommunityPost] {
        let snap = try await db.collection("communities").document(communityId)
            .collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        return snap.documents.compactMap { try? $0.data(as: CommunityPost.self) }
    }

    func createPost(communityId: String, authorId: String, authorName: String, authorAvatar: String, type: CommunityPost.PostType, title: String, content: String, tags: [String]) async throws -> String {
        let data: [String: Any] = [
            "communityId": communityId,
            "authorId": authorId,
            "authorName": authorName,
            "authorAvatar": authorAvatar,
            "type": type.rawValue,
            "title": title,
            "content": content,
            "images": [String](),
            "likes": 0,
            "commentCount": 0,
            "isPinned": false,
            "tags": tags,
            "createdAt": FieldValue.serverTimestamp()
        ]

        let ref = try await db.collection("communities").document(communityId)
            .collection("posts").addDocument(data: data)

        try await db.collection("communities").document(communityId).updateData([
            "postCount": FieldValue.increment(Int64(1))
        ])

        return ref.documentID
    }

    func toggleLike(communityId: String, postId: String, userId: String) async throws -> Bool {
        let likeRef = db.collection("communities").document(communityId)
            .collection("posts").document(postId)
            .collection("likes").document(userId)

        let snap = try await likeRef.getDocument()

        if snap.exists {
            try await likeRef.delete()
            try await db.collection("communities").document(communityId)
                .collection("posts").document(postId).updateData([
                    "likes": FieldValue.increment(Int64(-1))
                ])
            return false
        } else {
            try await likeRef.setData(["userId": userId, "createdAt": FieldValue.serverTimestamp()])
            try await db.collection("communities").document(communityId)
                .collection("posts").document(postId).updateData([
                    "likes": FieldValue.increment(Int64(1))
                ])
            return true
        }
    }

    // MARK: - Comments

    func getComments(communityId: String, postId: String) async throws -> [Comment] {
        let snap = try await db.collection("communities").document(communityId)
            .collection("posts").document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .getDocuments()
        return snap.documents.compactMap { try? $0.data(as: Comment.self) }
    }

    func addComment(communityId: String, postId: String, authorId: String, authorName: String, authorAvatar: String, content: String) async throws {
        let data: [String: Any] = [
            "authorId": authorId,
            "authorName": authorName,
            "authorAvatar": authorAvatar,
            "content": content,
            "createdAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("communities").document(communityId)
            .collection("posts").document(postId)
            .collection("comments").addDocument(data: data)

        try await db.collection("communities").document(communityId)
            .collection("posts").document(postId).updateData([
                "commentCount": FieldValue.increment(Int64(1))
            ])
    }
}
