import Foundation
import FirebaseFirestore
import UIKit

enum CarService {
    private static let db = Firestore.firestore()

    static func getUserCars(userId: String) async throws -> [CarBuild] {
        let snapshot = try await db.collection("cars")
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: CarBuild.self)
        }
    }

    static func getCarById(_ carId: String) async throws -> CarBuild? {
        let doc = try await db.collection("cars").document(carId).getDocument()
        return try? doc.data(as: CarBuild.self)
    }

    static func addCar(
        ownerId: String,
        year: String,
        make: String,
        model: String,
        trim: String,
        nickname: String,
        description: String,
        horsepower: String,
        torque: String,
        engine: String,
        drivetrain: String,
        transmission: String,
        weight: String,
        mods: [CarMod],
        photos: [UIImage]
    ) async throws -> String {
        var photoURLs: [String] = []
        if !photos.isEmpty {
            photoURLs = try await StorageService.uploadMultipleImages(photos, path: "cars/\(ownerId)")
        }

        let modsData = mods.map { ["name": $0.name, "category": $0.category] }

        let docRef = try await db.collection("cars").addDocument(data: [
            "ownerId": ownerId,
            "year": year,
            "make": make,
            "model": model,
            "trim": trim,
            "nickname": nickname,
            "description": description,
            "horsepower": horsepower,
            "torque": torque,
            "engine": engine,
            "drivetrain": drivetrain,
            "transmission": transmission,
            "weight": weight,
            "mods": modsData,
            "photos": photoURLs,
            "coverPhoto": photoURLs.first ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ])
        return docRef.documentID
    }

    static func deleteCar(_ carId: String) async throws {
        try await db.collection("cars").document(carId).delete()
    }
}
