import Foundation
import FirebaseFirestore

// MARK: - Events

struct CarEvent: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var date: String
    var time: String
    var location: String
    var address: String
    var category: String
    var imageURL: String
    var organizerId: String
    var organizerName: String
    var attendeeCount: Int
    var maxAttendees: Int?
    @ServerTimestamp var createdAt: Timestamp?
}

struct EventAttendee: Codable, Identifiable {
    var id: String { userId }
    var userId: String
    var userName: String
    var userAvatar: String
    @ServerTimestamp var joinedAt: Timestamp?
}

// MARK: - Marketplace

struct Listing: Codable, Identifiable {
    @DocumentID var id: String?
    var sellerId: String
    var sellerName: String
    var sellerAvatar: String
    var title: String
    var description: String
    var price: Double
    var condition: String
    var category: String
    var carFitment: String
    var images: [String]
    var location: String
    var status: String
    @ServerTimestamp var createdAt: Timestamp?
}

// MARK: - Videos

struct Video: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var videoURL: String
    var thumbnailURL: String
    var authorId: String
    var authorName: String
    var authorAvatar: String
    var category: String
    var difficulty: String
    var duration: String
    var views: Int
    var likes: Int
    @ServerTimestamp var createdAt: Timestamp?
}

// MARK: - User Profile

struct UserProfile: Codable, Identifiable {
    var id: String { uid }
    var uid: String
    var email: String
    var displayName: String
    var username: String
    var profileImageURL: String
    var bio: String
    var location: String
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
}
