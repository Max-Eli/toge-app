import Foundation
import FirebaseFirestore

struct ChatChannel: Identifiable, Codable {
    @DocumentID var id: String?
    var type: ChannelType
    var name: String
    var participants: [String]
    var participantNames: [String: String]
    var lastMessage: String
    var lastMessageAt: Date?
    var createdBy: String
    var createdAt: Date?

    enum ChannelType: String, Codable {
        case dm
        case group
    }

    /// Display name for the channel relative to the current user
    func displayName(currentUserId: String) -> String {
        if type == .group { return name }
        // For DMs, show the other participant's name
        let otherName = participantNames.first(where: { $0.key != currentUserId })?.value
        return otherName ?? "Unknown"
    }
}

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var channelId: String
    var senderId: String
    var senderName: String
    var senderAvatar: String
    var content: String
    var imageURL: String
    var createdAt: Date?
}
