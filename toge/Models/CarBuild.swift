import Foundation
import FirebaseFirestore

struct CarMod: Codable, Identifiable, Hashable {
    var id: String { "\(category)-\(name)" }
    let name: String
    let category: String
}

struct CarBuild: Identifiable, Codable {
    @DocumentID var id: String?
    let ownerId: String
    var year: String
    var make: String
    var model: String
    var trim: String
    var nickname: String
    var description: String
    var horsepower: String
    var torque: String
    var engine: String
    var drivetrain: String
    var transmission: String
    var weight: String
    var mods: [CarMod]
    var photos: [String]
    var coverPhoto: String
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, ownerId, year, make, model, trim, nickname, description
        case horsepower, torque, engine, drivetrain, transmission, weight
        case mods, photos, coverPhoto, createdAt, updatedAt
    }

    var displayTitle: String {
        [year, make, model].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
