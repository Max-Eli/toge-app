import Foundation
import FirebaseFirestore

final class ChatService {
    static let shared = ChatService()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Real-time Listeners

    func subscribeToChannels(userId: String, completion: @escaping ([ChatChannel]) -> Void) -> ListenerRegistration {
        let q = db.collection("channels")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)

        return q.addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            let channels = docs.compactMap { doc -> ChatChannel? in
                try? doc.data(as: ChatChannel.self)
            }
            completion(channels)
        }
    }

    func subscribeToMessages(channelId: String, completion: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        let q = db.collection("channels").document(channelId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .limit(to: 100)

        return q.addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            let messages = docs.compactMap { doc -> ChatMessage? in
                try? doc.data(as: ChatMessage.self)
            }
            completion(messages)
        }
    }

    // MARK: - Actions

    func sendMessage(channelId: String, senderId: String, senderName: String, senderAvatar: String, content: String) async throws {
        let messageData: [String: Any] = [
            "channelId": channelId,
            "senderId": senderId,
            "senderName": senderName,
            "senderAvatar": senderAvatar,
            "content": content,
            "imageURL": "",
            "createdAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("channels").document(channelId)
            .collection("messages").addDocument(data: messageData)

        try await db.collection("channels").document(channelId).updateData([
            "lastMessage": content,
            "lastMessageAt": FieldValue.serverTimestamp()
        ])
    }

    func createDM(userId: String, userName: String, otherUserId: String, otherUserName: String) async throws -> String {
        // Check for existing DM
        let q = db.collection("channels")
            .whereField("type", isEqualTo: "dm")
            .whereField("participants", arrayContains: userId)

        let snap = try await q.getDocuments()
        if let existing = snap.documents.first(where: {
            ($0.data()["participants"] as? [String])?.contains(otherUserId) == true
        }) {
            return existing.documentID
        }

        let data: [String: Any] = [
            "type": "dm",
            "name": "",
            "participants": [userId, otherUserId],
            "participantNames": [userId: userName, otherUserId: otherUserName],
            "lastMessage": "",
            "lastMessageAt": FieldValue.serverTimestamp(),
            "createdBy": userId,
            "createdAt": FieldValue.serverTimestamp()
        ]

        let ref = try await db.collection("channels").addDocument(data: data)
        return ref.documentID
    }
}
