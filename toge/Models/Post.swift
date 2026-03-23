import Foundation
import FirebaseFirestore

struct Post: Identifiable, Codable {
    @DocumentID var id: String?
    let authorId: String
    let authorName: String
    let authorAvatar: String
    var carName: String
    let content: String
    let images: [String]
    var likes: Int
    var commentCount: Int
    let createdAt: Date?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID(wrappedValue: nil)
        authorId = try container.decodeIfPresent(String.self, forKey: .authorId) ?? ""
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName) ?? ""
        authorAvatar = try container.decodeIfPresent(String.self, forKey: .authorAvatar) ?? ""
        carName = try container.decodeIfPresent(String.self, forKey: .carName) ?? ""
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        images = try container.decodeIfPresent([String].self, forKey: .images) ?? []
        likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    enum CodingKeys: String, CodingKey {
        case id, authorId, authorName, authorAvatar, carName, content, images, likes, commentCount, createdAt
    }
}

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var postId: String?
    let authorId: String
    let authorName: String
    let authorAvatar: String
    let content: String
    let createdAt: Date?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID(wrappedValue: nil)
        postId = try container.decodeIfPresent(String.self, forKey: .postId)
        authorId = try container.decodeIfPresent(String.self, forKey: .authorId) ?? ""
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName) ?? ""
        authorAvatar = try container.decodeIfPresent(String.self, forKey: .authorAvatar) ?? ""
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    enum CodingKeys: String, CodingKey {
        case id, postId, authorId, authorName, authorAvatar, content, createdAt
    }
}
