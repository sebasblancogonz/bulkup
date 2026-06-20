//
//  API.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import Combine
import Foundation

struct APIConfig {
    static let timeout: TimeInterval = 30.0

    // MARK: - Production-Ready Configuration

    static var baseURL: String {
        // First try to get from Info.plist (build configuration)
        if let urlString = Bundle.main.object(
            forInfoDictionaryKey: "API_BASE_URL"
        ) as? String,
            !urlString.isEmpty
        {
            return urlString
        }

        // Fallback based on build configuration
        #if DEBUG
            return "http://localhost:8080"
        #else
            return "https://api.getbulkup.com"
        #endif
    }

    static var gotifyURL: String {
        if let urlString = Bundle.main.object(
            forInfoDictionaryKey: "GOTIFY_URL"
        ) as? String,
            !urlString.isEmpty
        {
            return urlString
        }

        #if DEBUG
            return "https://notifications.getbulkup.com"
        #else
            return "https://notifications.getbulkup.com"
        #endif
    }

    static var environment: Environment {
        if let envString = Bundle.main.object(
            forInfoDictionaryKey: "ENVIRONMENT"
        ) as? String {
            return Environment(rawValue: envString) ?? .development
        }

        #if DEBUG
            return .development
        #else
            return .production
        #endif
    }

    enum Environment: String {
        case development = "development"
        case staging = "staging"
        case production = "production"

        var enablesLogging: Bool {
            switch self {
            case .development, .staging: return true
            case .production: return false
            }
        }

        var allowsInsecureHTTP: Bool {
            return self == .development
        }
    }

    // MARK: - Configuration Validation

    static func validateConfiguration() {
        assert(!baseURL.isEmpty, "API Base URL cannot be empty")

        if environment == .production {
            assert(baseURL.hasPrefix("https://"), "Production must use HTTPS")
        }

        print("🔧 API Configuration:")
        print("   Environment: \(environment.rawValue)")
        print("   Base URL: \(baseURL)")
        print(
            "   Logging: \(environment.enablesLogging ? "Enabled" : "Disabled")"
        )
    }
}


struct AuthResponse: Codable {
    let userId: String
    let email: String
    let name: String
    let dateOfBirth: Date?
    let profileImageURL: String?
    let token: String
    let friendCode: String?
    let createdAt: Date
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
    let dateOfBirth: Date?
    
    init(email: String, password: String, name: String, dateOfBirth: Date? = nil) {
        self.email = email
        self.password = password
        self.name = name
        self.dateOfBirth = dateOfBirth
    }
}

struct AppleSignInRequest: Codable {
    let identityToken: String
    let firstName: String?
    let lastName: String?
}

struct UpdateProfileRequest: Codable {
    let name: String?
    let dateOfBirth: Date?
    let profileImageURL: String?
    let nextReviewDate: Date?
    let allergies: [String]?
    let likedFoods: [String]?
    let dislikedFoods: [String]?

    init(name: String? = nil, dateOfBirth: Date? = nil, profileImageURL: String? = nil, nextReviewDate: Date? = nil, allergies: [String]? = nil, likedFoods: [String]? = nil, dislikedFoods: [String]? = nil) {
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.profileImageURL = profileImageURL
        self.nextReviewDate = nextReviewDate
        self.allergies = allergies
        self.likedFoods = likedFoods
        self.dislikedFoods = dislikedFoods
    }
}

struct UploadImageRequest: Codable {
    let imageUrl: String
}

struct ZiplineUploadResponse: Codable {
    let files: [ZiplineFile]
}

struct ZiplineFile: Codable {
    let id: String
    let type: String
    let url: String
}

struct ProfileResponse: Codable {
    let userId: String
    let email: String
    let name: String
    let dateOfBirth: Date?
    let profileImageURL: String?
    let friendCode: String?
    let nextReviewDate: Date?
    let createdAt: Date
    let updatedAt: Date
    var allergies: [String]?
    var likedFoods: [String]?
    var dislikedFoods: [String]?
}


struct LoadDietPlanResponse: Codable {
    let success: Bool?
    let dietData: [ServerDietDay]?
    let planId: String?
    let filename: String?
    let createdAt: String?
    let updatedAt: String?

    private enum CodingKeys: String, CodingKey {
        case success
        case dietData, dietDataSnake = "diet_data"
        case planId, planIdSnake = "plan_id", planIdMongo = "_id"
        case filename
        case createdAt, createdAtSnake = "created_at"
        case updatedAt, updatedAtSnake = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success)
        dietData = try container.decodeIfPresent([ServerDietDay].self, forKey: .dietData)
            ?? container.decodeIfPresent([ServerDietDay].self, forKey: .dietDataSnake)
        planId = try container.decodeIfPresent(String.self, forKey: .planId)
            ?? container.decodeIfPresent(String.self, forKey: .planIdSnake)
            ?? container.decodeIfPresent(String.self, forKey: .planIdMongo)
        filename = try container.decodeIfPresent(String.self, forKey: .filename)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
            ?? container.decodeIfPresent(String.self, forKey: .createdAtSnake)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
            ?? container.decodeIfPresent(String.self, forKey: .updatedAtSnake)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(success, forKey: .success)
        try container.encodeIfPresent(dietData, forKey: .dietData)
        try container.encodeIfPresent(planId, forKey: .planId)
        try container.encodeIfPresent(filename, forKey: .filename)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

struct LoadDietPlanOuterResponse: Codable {
    let success: Bool
    let data: LoadDietPlanResponse

    private enum CodingKeys: String, CodingKey {
        case success, data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)

        if let nestedData = try? container.decode(LoadDietPlanResponse.self, forKey: .data) {
            self.data = nestedData
        } else {
            // Fallback: try decoding flat response (no data wrapper)
            self.data = try LoadDietPlanResponse(from: decoder)
        }
    }
}

struct ServerMacros: Codable {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

struct ServerDietDay: Codable {
    let day: String
    let meals: [ServerMeal]
    var supplements: [ServerSupplement]?
    var macros: ServerMacros? = nil
    var allowsCheatMeal: Bool? = nil
}

struct ServerMeal: Codable {
    let type: String
    let time: String
    let date: String?
    let notes: String?
    let options: [MealOptionData]?
    let conditions: ServerMealConditions?

    struct MealOptionData: Codable {
        let description: String
        let ingredients: [String]
        let instructions: [String]?

        enum CodingKeys: String, CodingKey {
            case description, ingredients, instructions
        }

        init(description: String, ingredients: [String], instructions: [String]?) {
            self.description = description
            self.ingredients = ingredients
            self.instructions = instructions
        }

        // Tolerate plans where an option omits ingredients/description (older or
        // partially-parsed data) instead of failing the whole list decode.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            description = (try? c.decode(String.self, forKey: .description)) ?? ""
            ingredients = (try? c.decode([String].self, forKey: .ingredients)) ?? []
            instructions = try? c.decode([String].self, forKey: .instructions)
        }
    }
}

struct ServerMealConditions: Codable {
    let trainingDays: ServerConditionalMeal?
    let nonTrainingDays: ServerConditionalMeal?

    enum CodingKeys: String, CodingKey {
        case trainingDays = "training_days"
        case nonTrainingDays = "non_training_days"
    }
}

struct ServerConditionalMeal: Codable {
    let description: String
    let ingredients: [String]?
}

struct ServerSupplement: Codable {
    let name: String
    let dosage: String
    let timing: String
    let frequency: String
    let notes: String?
}

struct LoadTrainingPlanOuterResponse: Codable {
    let success: Bool
    let data: ServerWorkout
}

struct ServerTrainingDay: Codable {
    let day: String
    let workoutName: String?
    let output: [ServerExercise]?

    enum CodingKeys: String, CodingKey {
        case day
        case workoutName = "workout_name"
        case output
    }
}

struct ServerExercise: Codable {
    let name: String
    let sets: Int
    let reps: String
    let restSeconds: Int
    let notes: String?
    let tempo: String?
    let weightTracking: Bool

    enum CodingKeys: String, CodingKey {
        case name, sets, notes, tempo
        case restSeconds = "rest_seconds"
        case weightTracking = "weight_tracking"
        case reps
    }

    // ✅ AÑADIR: Inicializador público
    init(
        name: String,
        sets: Int,
        reps: String,
        restSeconds: Int,
        notes: String? = nil,
        tempo: String? = nil,
        weightTracking: Bool
    ) {
        self.name = name
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.notes = notes
        self.tempo = tempo
        self.weightTracking = weightTracking
    }

    // Custom decoding para manejar reps como Int o String
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        sets = try container.decode(Int.self, forKey: .sets)
        restSeconds = try container.decode(Int.self, forKey: .restSeconds)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        tempo = try container.decodeIfPresent(String.self, forKey: .tempo)
        weightTracking = try container.decode(
            Bool.self,
            forKey: .weightTracking
        )

        // Manejar reps como Int o String
        if let repsInt = try? container.decode(Int.self, forKey: .reps) {
            reps = String(repsInt)
        } else {
            reps = try container.decode(String.self, forKey: .reps)
        }
    }

    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(sets, forKey: .sets)
        try container.encode(restSeconds, forKey: .restSeconds)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(tempo, forKey: .tempo)
        try container.encode(weightTracking, forKey: .weightTracking)
        try container.encode(reps, forKey: .reps)
    }
}

struct SaveWeightsRequest: Codable {
    let userId: String
    let planId: String
    let weightRecord: WeightRecordRequest
    let weekStart: String
}

struct WeightRecordRequest: Codable {
    let day: String
    let exerciseName: String
    let exerciseIndex: Int
    let sets: [ServerWeightSet]
    let note: String
}

struct ServerWeightSet: Codable {    
    let setNumber: Int?
    let weight: Double
    let reps: Int
}

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(String)
    case invalidClientRequest
    case unauthorized
    case invalidRequest(HTTPURLResponse)
    case serverError(Int)
    case requestFailed
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let message):
            return message
        case .unauthorized:
            return "Unauthorized access"
        case .invalidClientRequest:
            return "Invalid client request"
        case .invalidRequest(let httpResponse):
            return "Invalid request parameters (HTTP response: \(httpResponse))"
        case .serverError(let code):
            return "Server error: \(code)"
        case .requestFailed:
            return "Request failed"
        case .notFound:
            return "Not Found"
        }
    }
}

struct EmptyResponse: Codable {}

// MARK: - Workout Sessions

struct ExerciseSessionData: Codable {
    let name: String
    let exerciseIndex: Int
    let setsCompleted: Int
    let setsTotal: Int
    let totalVolume: Double
    let skipped: Bool
}

struct SaveWorkoutSessionRequest: Codable {
    let userId: String
    let planId: String?
    let dayName: String
    let workoutName: String?
    let durationSeconds: Int
    let totalVolume: Double
    let totalSets: Int
    let exercisesCompleted: Int
    let exercisesTotal: Int
    let exercisesSkipped: Int
    let exercises: [ExerciseSessionData]
    let date: String
}

struct WorkoutSessionRecord: Codable, Identifiable {
    let _id: String?
    let userId: String
    let planId: String?
    let dayName: String
    let workoutName: String?
    let durationSeconds: Int
    let totalVolume: Double
    let totalSets: Int
    let exercisesCompleted: Int
    let exercisesTotal: Int
    let exercisesSkipped: Int
    let exercises: [ExerciseSessionData]?
    let date: String
    let completedAt: String?

    var id: String { _id ?? date }

    var formattedDuration: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var formattedVolume: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fk", totalVolume / 1000)
        }
        return String(format: "%.0f", totalVolume)
    }
}

struct LoadWeightsRequest: Codable {
    let userId: String
    let weekStart: String
}

struct LoadWeightsResponse: Codable {
    let success: Bool?
    let weights: [ServerWeightRecord]?
}

struct ServerWeightRecord: Codable {
    let day: String
    let exerciseName: String
    let exerciseIndex: Int
    let sets: [ServerWeightSet]?
    let planId: String?
    let note: String?
}

struct LoadWeightsOuterResponse: Codable {
    let success: Bool
    let data: LoadWeightsResponse
}

struct CreateTrainingPlanRequest: Codable {
    let userId: String
    let filename: String
    let trainingData: [ServerTrainingDay]
    let planStartDate: Date?
    let planEndDate: Date?
}

struct CreateTrainingPlanResponse: Codable {
    let success: Bool
    let message: String?
    let planId: String
}

struct ActivateTrainingPlanRequest: Codable {
    let userId: String
}

struct DeleteTrainingPlanRequest: Codable {
    let userId: String
}

// Add this new model to your API.swift file
struct ServerWorkout: Codable, Identifiable {
    let id: String?
    let userId: String
    let filename: String
    let trainingData: [ServerTrainingDay]?
    let active: Bool
    let planStartDate: Date?  // This will be nil until you update your backend
    let planEndDate: Date?  // This will be nil until you update your backend
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, filename, trainingData, active
        case planStartDate, planEndDate, createdAt, updatedAt
    }

    // Custom decoder to handle the actual response format
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle _id field (MongoDB ObjectID)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        filename = try container.decode(String.self, forKey: .filename)
        trainingData = try container.decodeIfPresent(
            [ServerTrainingDay].self,
            forKey: .trainingData
        )
        active = try container.decode(Bool.self, forKey: .active)

        // These fields don't exist in your current backend response, so they'll be nil for now
        planStartDate = try container.decodeIfPresent(
            Date.self,
            forKey: .planStartDate
        )
        planEndDate = try container.decodeIfPresent(
            Date.self,
            forKey: .planEndDate
        )

        // Handle date parsing - your backend returns ISO dates
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

// Also add this request model for loading plans
struct LoadPlanRequest: Codable {
    let userId: String
}

// MARK: - Diet Plan Management Models

struct ServerDietPlan: Codable, Identifiable {
    let id: String?
    let userId: String
    let filename: String
    let dietData: [ServerDietDay]?
    let active: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, filename, dietData, active, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        filename = try container.decode(String.self, forKey: .filename)
        dietData = try container.decodeIfPresent([ServerDietDay].self, forKey: .dietData)
        active = try container.decode(Bool.self, forKey: .active)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct CreateDietPlanRequest: Codable {
    let userId: String
    let filename: String
    let dietData: [ServerDietDay]
}

struct CreateDietPlanResponse: Codable {
    let planId: String
}

struct ActivateDietPlanRequest: Codable {
    let userId: String
}

struct DeleteDietPlanRequest: Codable {
    let userId: String
}

// MARK: - Shared Plan Models

struct SharePlanRequest: Codable {
    let userId: String
    let planId: String
}

struct SharePlanResponse: Codable {
    let code: String
    let expiresAt: Date
}

struct ImportSharedPlanRequest: Codable {
    let userId: String
    let code: String
}

struct ImportSharedPlanResponse: Codable {
    let planId: String
    let filename: String
}

// MARK: - Meal Tracking Models

struct MealCompletionData: Codable {
    let mealType: String
    let mealOrder: Int
    var completed: Bool
    var notes: String?
    var completedAt: Date?
}

struct DailyMealTrackingResponse: Codable {
    let id: String?
    let userId: String
    let planId: String
    let date: String
    let dayName: String
    let meals: [MealCompletionData]
    let cheatMealLog: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId, planId, date, dayName, meals, cheatMealLog, createdAt, updatedAt
    }
}

struct SaveMealTrackingRequest: Codable {
    let userId: String
    let planId: String
    let date: String
    let dayName: String
    let meals: [MealCompletionData]
    var cheatMealLog: String?
}

struct ComplianceStatsResponse: Codable {
    let totalMeals: Int
    let completedMeals: Int
    let complianceRate: Double
    let currentStreak: Int
    let daysTracked: Int
}

// MARK: - Friends & Streak Models

struct FriendProfile: Codable, Identifiable {
    let userId: String
    let name: String
    let profileImageURL: String?
    let currentStreak: Int
    let longestStreak: Int
    let totalDays: Int

    var id: String { userId }
}

struct TrainingStreakResponse: Codable {
    let userId: String
    let currentStreak: Int
    let longestStreak: Int
    let totalDays: Int
}

struct LeaderboardResponse: Codable {
    let friends: [FriendProfile]
    let myStreak: TrainingStreakResponse
}

struct AddFriendRequest: Codable {
    let userId: String
    let friendCode: String
}

struct AddFriendResponse: Codable {
    let friendUserId: String
    let friendName: String
    let friendImageURL: String?
}

struct CompleteWorkoutRequest: Codable {
    let userId: String
    let date: String
    let planId: String?
    let dayName: String?
}

struct FriendCodeResponse: Codable {
    let friendCode: String
}

// MARK: - Resilient list decoding

/// Wraps a Decodable so one malformed element in an array doesn't fail the whole
/// decode. Used for plan lists, which aggregate user-uploaded / AI-parsed data of
/// varying quality. Decode `[FailableDecodable<T>]` then compactMap `.value`.
struct FailableDecodable<T: Codable>: Codable {
    let value: T?
    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
}
