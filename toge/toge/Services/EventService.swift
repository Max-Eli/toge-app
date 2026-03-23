import Foundation
import FirebaseFirestore

enum EventService {
    private static let db = Firestore.firestore()

    static func getEvents() async throws -> [CarEvent] {
        let snapshot = try await db.collection("events")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: CarEvent.self) }
    }

    static func getEvents(category: String) async throws -> [CarEvent] {
        let snapshot = try await db.collection("events")
            .whereField("category", isEqualTo: category)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: CarEvent.self) }
    }

    static func createEvent(
        title: String,
        description: String,
        date: String,
        time: String,
        location: String,
        address: String,
        category: String,
        imageURL: String,
        organizerId: String,
        organizerName: String,
        maxAttendees: Int?
    ) async throws -> String {
        var data: [String: Any] = [
            "title": title,
            "description": description,
            "date": date,
            "time": time,
            "location": location,
            "address": address,
            "category": category,
            "imageURL": imageURL,
            "organizerId": organizerId,
            "organizerName": organizerName,
            "attendeeCount": 0,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let maxAttendees {
            data["maxAttendees"] = maxAttendees
        }
        let ref = try await db.collection("events").addDocument(data: data)
        return ref.documentID
    }

    static func toggleRSVP(eventId: String, userId: String, userName: String, userAvatar: String, isAttending: Bool) async throws {
        let ref = db.collection("events").document(eventId)
        let attendeeRef = ref.collection("attendees").document(userId)

        if isAttending {
            try await attendeeRef.delete()
            try await ref.updateData(["attendeeCount": FieldValue.increment(Int64(-1))])
        } else {
            try await attendeeRef.setData([
                "userId": userId,
                "userName": userName,
                "userAvatar": userAvatar,
                "joinedAt": FieldValue.serverTimestamp()
            ])
            try await ref.updateData(["attendeeCount": FieldValue.increment(Int64(1))])
        }
    }

    static func getAttendees(eventId: String) async throws -> [EventAttendee] {
        let snapshot = try await db.collection("events").document(eventId)
            .collection("attendees").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: EventAttendee.self) }
    }

    static func isUserAttending(eventId: String, userId: String) async throws -> Bool {
        let doc = try await db.collection("events").document(eventId)
            .collection("attendees").document(userId).getDocument()
        return doc.exists
    }
}
