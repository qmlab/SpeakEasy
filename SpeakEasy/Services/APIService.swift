//
//  APIService.swift
//  SpeakEasy
//

import Foundation
import SwiftUI

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "https://speakeasy-backend-jswsybdb.fly.dev"
    
    @Published var playerId: String?
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let playerIdKey = "speakeasy_player_id"
    
    init() {
        playerId = UserDefaults.standard.string(forKey: playerIdKey)
    }
    
    func createPlayer(name: String) async throws -> PlayerResponse {
        let url = URL(string: "\(baseURL)/players/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["name": name]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let player = try JSONDecoder().decode(PlayerResponse.self, from: data)
        
        DispatchQueue.main.async {
            self.playerId = player.id
            UserDefaults.standard.set(player.id, forKey: self.playerIdKey)
        }
        
        return player
    }
    
    func getOrCreatePlayer(name: String = "Player") async throws -> String {
        if let existingId = playerId {
            return existingId
        }
        let player = try await createPlayer(name: name)
        return player.id
    }
    
    func submitSayWord(objectId: String, spokenText: String) async throws -> SayWordResponse {
        let playerId = try await getOrCreatePlayer()
        
        let url = URL(string: "\(baseURL)/game/say-word")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SayWordRequest(playerId: playerId, objectId: objectId, spokenText: spokenText)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(SayWordResponse.self, from: data)
    }
    
    func submitFindObject(objectImageId: String, tapX: Double, tapY: Double) async throws -> FindObjectResponse {
        let playerId = try await getOrCreatePlayer()
        
        let url = URL(string: "\(baseURL)/game/find-object")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = FindObjectRequest(playerId: playerId, objectImageId: objectImageId, tapX: tapX, tapY: tapY)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(FindObjectResponse.self, from: data)
    }
    
    func getPlayerStats() async throws -> PlayerStats? {
        guard let playerId = playerId else { return nil }
        
        let url = URL(string: "\(baseURL)/players/\(playerId)/stats")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(PlayerStats.self, from: data)
    }
    
    func getPlayerHistory(featureType: Int? = nil) async throws -> [AttemptResponse] {
        guard let playerId = playerId else { return [] }
        
        var urlString = "\(baseURL)/players/\(playerId)/history"
        if let featureType = featureType {
            urlString += "?feature_type=\(featureType)"
        }
        
        let url = URL(string: urlString)!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([AttemptResponse].self, from: data)
    }
    
    func createObject(name: String, category: String) async throws -> ObjectResponse {
        let url = URL(string: "\(baseURL)/objects/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["name": name, "category": category]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ObjectResponse.self, from: data)
    }
    
    func getObjects(category: String? = nil) async throws -> [ObjectListResponse] {
        var urlString = "\(baseURL)/objects/"
        if let category = category {
            urlString += "?category=\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category)"
        }
        
        let url = URL(string: urlString)!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([ObjectListResponse].self, from: data)
    }
    
    func getCategories() async throws -> [String] {
        let url = URL(string: "\(baseURL)/objects/categories")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([String].self, from: data)
    }
    
    func getObject(objectId: String) async throws -> ObjectDetailResponse {
        let url = URL(string: "\(baseURL)/objects/\(objectId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(ObjectDetailResponse.self, from: data)
    }
    
    func getObjectImages(objectId: String, imageType: ImageType? = nil) async throws -> [ObjectImageResponse] {
        var urlString = "\(baseURL)/objects/\(objectId)/images"
        if let imageType = imageType {
            urlString += "?image_type=\(imageType.rawValue)"
        }
        
        let url = URL(string: urlString)!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([ObjectImageResponse].self, from: data)
    }
    
    func getFlashcardImage(objectId: String) async throws -> ObjectImageResponse? {
        let images = try await getObjectImages(objectId: objectId, imageType: .flashcard)
        return images.first
    }
    
    func getFindObjectImage(objectId: String) async throws -> ObjectImageResponse? {
        let images = try await getObjectImages(objectId: objectId, imageType: .findObject)
        return images.first
    }
    
    func getThumbnailImage(objectId: String) async throws -> ObjectImageResponse? {
        let images = try await getObjectImages(objectId: objectId, imageType: .thumbnail)
        return images.first
    }
    
    func recordProgress(objectId: String, rating: Double) async throws -> RecordProgressResponse {
        let playerId = try await getOrCreatePlayer()
        
        let url = URL(string: "\(baseURL)/progress/record")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = RecordProgressRequest(playerId: playerId, objectId: objectId, rating: rating)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(RecordProgressResponse.self, from: data)
    }
    
    func getProgress() async throws -> [ProgressResponse] {
        guard let playerId = playerId else { return [] }
        
        let url = URL(string: "\(baseURL)/progress/\(playerId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([ProgressResponse].self, from: data)
    }
    
    func getObjectProgress(objectId: String) async throws -> ProgressResponse? {
        guard let playerId = playerId else { return nil }
        
        let url = URL(string: "\(baseURL)/progress/\(playerId)/\(objectId)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            if data.isEmpty || String(data: data, encoding: .utf8) == "null" {
                return nil
            }
            return try JSONDecoder().decode(ProgressResponse.self, from: data)
        }
        return nil
    }
    
    func resetProgress() async throws {
        guard let playerId = playerId else { return }
        
        let url = URL(string: "\(baseURL)/progress/\(playerId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let _ = try await URLSession.shared.data(for: request)
    }
    
    func appleSignIn(appleUserId: String, name: String?, email: String?) async throws -> AppleSignInResponse {
        let url = URL(string: "\(baseURL)/auth/apple")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AppleSignInRequest(appleUserId: appleUserId, name: name, email: email)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AppleSignInResponse.self, from: data)
    }
    
    func getPlayerByAppleId(appleUserId: String) async throws -> PlayerResponse? {
        let url = URL(string: "\(baseURL)/auth/player/\(appleUserId)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
            return nil
        }
        
        return try JSONDecoder().decode(PlayerResponse.self, from: data)
    }
    
    func guestSignIn(deviceId: String) async throws -> GuestSignInResponse {
        let url = URL(string: "\(baseURL)/auth/guest")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = GuestSignInRequest(deviceId: deviceId)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(GuestSignInResponse.self, from: data)
    }
    
    func getPlayerByDeviceId(deviceId: String) async throws -> PlayerResponse? {
        let url = URL(string: "\(baseURL)/auth/guest/\(deviceId)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
            return nil
        }
        
        return try JSONDecoder().decode(PlayerResponse.self, from: data)
    }
}

struct PlayerResponse: Codable {
    let id: String
    let name: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SayWordRequest: Codable {
    let playerId: String
    let objectId: String
    let spokenText: String
    
    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case objectId = "object_id"
        case spokenText = "spoken_text"
    }
}

struct SayWordResponse: Codable {
    let score: Int
    let isCorrect: Bool
    let targetWord: String
    let spokenText: String
    let feedback: String
    let attemptId: String
    
    enum CodingKeys: String, CodingKey {
        case score
        case isCorrect = "is_correct"
        case targetWord = "target_word"
        case spokenText = "spoken_text"
        case feedback
        case attemptId = "attempt_id"
    }
}

struct FindObjectRequest: Codable {
    let playerId: String
    let objectImageId: String
    let tapX: Double
    let tapY: Double
    
    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case objectImageId = "object_image_id"
        case tapX = "tap_x"
        case tapY = "tap_y"
    }
}

struct FindObjectResponse: Codable {
    let isCorrect: Bool
    let score: Int
    let feedback: String
    let correctLocation: BoundingBoxLocation?
    let attemptId: String
    
    enum CodingKeys: String, CodingKey {
        case isCorrect = "is_correct"
        case score, feedback
        case correctLocation = "correct_location"
        case attemptId = "attempt_id"
    }
}

struct BoundingBoxLocation: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct PlayerStats: Codable {
    let playerId: String
    let playerName: String
    let totalAttempts: Int
    let correctAttempts: Int
    let accuracyPercentage: Double
    let sayWordAttempts: Int
    let sayWordCorrect: Int
    let findObjectAttempts: Int
    let findObjectCorrect: Int
    let averageScore: Double
    
    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case playerName = "player_name"
        case totalAttempts = "total_attempts"
        case correctAttempts = "correct_attempts"
        case accuracyPercentage = "accuracy_percentage"
        case sayWordAttempts = "say_word_attempts"
        case sayWordCorrect = "say_word_correct"
        case findObjectAttempts = "find_object_attempts"
        case findObjectCorrect = "find_object_correct"
        case averageScore = "average_score"
    }
}

struct AttemptResponse: Codable, Identifiable {
    let id: String
    let playerId: String
    let objectId: String
    let featureType: Int
    let score: Int
    let spokenText: String?
    let tapX: Double?
    let tapY: Double?
    let isCorrect: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case playerId = "player_id"
        case objectId = "object_id"
        case featureType = "feature_type"
        case score
        case spokenText = "spoken_text"
        case tapX = "tap_x"
        case tapY = "tap_y"
        case isCorrect = "is_correct"
        case createdAt = "created_at"
    }
}

struct ObjectResponse: Codable {
    let id: String
    let name: String
    let category: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, category
        case createdAt = "created_at"
    }
}

struct ObjectListResponse: Codable, Identifiable {
    let id: String
    let name: String
    let category: String
    let imageCount: Int
    let thumbnailUrl: String?
    let flashcardUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, category
        case imageCount = "image_count"
        case thumbnailUrl = "thumbnail_url"
        case flashcardUrl = "flashcard_url"
    }
    
    var objectCategory: ObjectCategory? {
        ObjectCategory(rawValue: category)
    }
    
    var color: Color {
        objectCategory?.color ?? .gray
    }
    
    var icon: String {
        objectCategory?.icon ?? "photo.fill"
    }
}

enum ImageType: String, Codable {
    case flashcard = "flashcard"
    case findObject = "find_object"
    case thumbnail = "thumbnail"
}

struct ObjectImageResponse: Codable, Identifiable {
    let id: String
    let objectId: String
    let imageUrl: String
    let imageType: String
    let createdAt: String
    let boundingBoxes: [BoundingBoxResponse]
    
    enum CodingKeys: String, CodingKey {
        case id
        case objectId = "object_id"
        case imageUrl = "image_url"
        case imageType = "image_type"
        case createdAt = "created_at"
        case boundingBoxes = "bounding_boxes"
    }
}

struct BoundingBoxResponse: Codable, Identifiable {
    let id: String
    let objectImageId: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case objectImageId = "object_image_id"
        case x, y, width, height
        case createdAt = "created_at"
    }
}

struct ObjectDetailResponse: Codable {
    let id: String
    let name: String
    let category: String
    let createdAt: String
    let images: [ObjectImageResponse]
    
    enum CodingKeys: String, CodingKey {
        case id, name, category
        case createdAt = "created_at"
        case images
    }
}

struct RecordProgressRequest: Codable {
    let playerId: String
    let objectId: String
    let rating: Double
    
    enum CodingKeys: String, CodingKey {
        case playerId = "player_id"
        case objectId = "object_id"
        case rating
    }
}

struct RecordProgressResponse: Codable {
    let success: Bool
    let isLearned: Bool
    let lastRating: Double
    let practiceCount: Int
    let consecutiveFailedAttempts: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case isLearned = "is_learned"
        case lastRating = "last_rating"
        case practiceCount = "practice_count"
        case consecutiveFailedAttempts = "consecutive_failed_attempts"
        case message
    }
}

struct ProgressResponse: Codable, Identifiable {
    let id: String
    let playerId: String
    let objectId: String
    let lastRating: Double
    let practiceCount: Int
    let consecutiveFailedAttempts: Int
    let isLearned: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case playerId = "player_id"
        case objectId = "object_id"
        case lastRating = "last_rating"
        case practiceCount = "practice_count"
        case consecutiveFailedAttempts = "consecutive_failed_attempts"
        case isLearned = "is_learned"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct AppleSignInRequest: Codable {
    let appleUserId: String
    let name: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case appleUserId = "apple_user_id"
        case name
        case email
    }
}

struct AppleSignInResponse: Codable {
    let id: String
    let name: String
    let appleUserId: String
    let email: String?
    let isNewUser: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, email
        case appleUserId = "apple_user_id"
        case isNewUser = "is_new_user"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct GuestSignInRequest: Codable {
    let deviceId: String
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
    }
}

struct GuestSignInResponse: Codable {
    let id: String
    let name: String
    let deviceId: String
    let isGuest: Bool
    let isNewUser: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case deviceId = "device_id"
        case isGuest = "is_guest"
        case isNewUser = "is_new_user"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
