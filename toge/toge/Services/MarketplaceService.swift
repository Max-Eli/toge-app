import Foundation
import FirebaseFirestore
import UIKit

enum MarketplaceService {
    private static let db = Firestore.firestore()

    static func getListings() async throws -> [Listing] {
        let snapshot = try await db.collection("listings")
            .whereField("status", isEqualTo: "active")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Listing.self) }
    }

    static func createListing(
        sellerId: String,
        sellerName: String,
        sellerAvatar: String,
        title: String,
        description: String,
        price: Double,
        condition: String,
        category: String,
        carFitment: String,
        location: String,
        imageData: [Data]
    ) async throws -> String {
        var imageURLs: [String] = []
        if !imageData.isEmpty {
            imageURLs = try await StorageService.uploadMultipleImages(images: imageData, path: "listings/\(sellerId)")
        }

        let docRef = try await db.collection("listings").addDocument(data: [
            "sellerId": sellerId,
            "sellerName": sellerName,
            "sellerAvatar": sellerAvatar,
            "title": title,
            "description": description,
            "price": price,
            "condition": condition,
            "category": category,
            "carFitment": carFitment,
            "images": imageURLs,
            "location": location,
            "status": "active",
            "createdAt": FieldValue.serverTimestamp()
        ])
        return docRef.documentID
    }

    static func markAsSold(listingId: String) async throws {
        try await db.collection("listings").document(listingId)
            .updateData(["status": "sold"])
    }

    static func deleteListing(listingId: String) async throws {
        try await db.collection("listings").document(listingId).delete()
    }

    static func saveListing(userId: String, listingId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("savedListings").document(listingId)
            .setData(["savedAt": FieldValue.serverTimestamp()])
    }

    static func unsaveListing(userId: String, listingId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("savedListings").document(listingId).delete()
    }

    static func getSavedListingIds(userId: String) async throws -> [String] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("savedListings").getDocuments()
        return snapshot.documents.map { $0.documentID }
    }
}
