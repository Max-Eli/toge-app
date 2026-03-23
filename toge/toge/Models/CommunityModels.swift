import Foundation
import FirebaseFirestore

struct Community: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var type: CommunityType
    var category: String
    var ownerId: String
    var ownerName: String
    var bannerURL: String
    var avatarURL: String
    var memberCount: Int
    var postCount: Int
    var rules: [String]
    var createdAt: Date?

    enum CommunityType: String, Codable, CaseIterable {
        case `public`
        case `private`

        var label: String {
            switch self {
            case .public: return "Public"
            case .private: return "Private"
            }
        }

        var icon: String {
            switch self {
            case .public: return "globe"
            case .private: return "lock.fill"
            }
        }
    }
}

struct CommunityPost: Identifiable, Codable {
    @DocumentID var id: String?
    var communityId: String
    var authorId: String
    var authorName: String
    var authorAvatar: String
    var type: PostType
    var title: String
    var content: String
    var images: [String]
    var likes: Int
    var commentCount: Int
    var isPinned: Bool
    var tags: [String]
    var createdAt: Date?

    enum PostType: String, Codable, CaseIterable {
        case discussion
        case question
        case build
        case media

        var label: String { rawValue.capitalized }

        var icon: String {
            switch self {
            case .discussion: return "bubble.left.and.bubble.right"
            case .question: return "questionmark.circle"
            case .build: return "wrench.and.screwdriver"
            case .media: return "photo"
            }
        }
    }
}

struct CommunityMember: Identifiable, Codable {
    var userId: String
    var role: MemberRole
    var joinedAt: Date?

    var id: String { userId }

    enum MemberRole: String, Codable {
        case owner
        case moderator
        case member
    }
}

// Comment is defined in Post.swift
