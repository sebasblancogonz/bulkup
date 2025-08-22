//
//  API.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import Combine
import Foundation

struct APIConfig {
    static let timeout: TimeInterval = 30.0
    
    // MARK: - Production-Ready Configuration
    
    static var baseURL: String {
        // First try to get from Info.plist (build configuration)
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !urlString.isEmpty {
            return urlString
        }
        
        // Fallback based on build configuration
        #if DEBUG
        return "http://localhost:8080"
        #else
        return "https://weight-tracker-backend.tme3al.easypanel.host/" 
        #endif
    }
    
    static var environment: Environment {
        if let envString = Bundle.main.object(forInfoDictionaryKey: "ENVIRONMENT") as? String {
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
        print("   Logging: \(environment.enablesLogging ? "Enabled" : "Disabled")")
    }
}

struct AuthResponse: Codable {
    let userId: String
    let email: String
    let name: String
    let token: String
    let createdAt: String?
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct LoadDietPlanResponse: Codable {
    let success: Bool
    let dietData: [ServerDietDay]?
    let planId: String?
    let filename: String?
    let createdAt: String?
    let updatedAt: String?
}

struct LoadDietPlanOuterResponse: Codable {
    let success: Bool
    let data: LoadDietPlanResponse
}

struct ServerDietDay: Codable {
    let day: String
    let meals: [ServerMeal]
    let supplements: [ServerSupplement]?
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
        let instructions: [String]?  // <-- Optional now
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
    let ingredients: [String]
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
    let data: LoadTrainingPlanResponse
}

struct LoadTrainingPlanResponse: Codable {
    let success: Bool
    let trainingData: [ServerTrainingDay]?
    let planId: String?
    let filename: String?
    let createdAt: String?
    let updatedAt: String?
}

struct ServerTrainingDay: Codable {
    let day: String
    let workoutName: String?
    let output: [ServerExercise]

    enum CodingKeys: String, CodingKey {
        case day
        case workoutName = "workout_name"
        case output
    }
}

struct ServerExercise: Codable {
    let name: String
    let sets: Int
    let reps: String  // Mantener como String
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

    // ✅ ARREGLO: Custom decoding para manejar reps como Int o String
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

        // ✅ Manejar reps como Int o String
        if let repsInt = try? container.decode(Int.self, forKey: .reps) {
            reps = String(repsInt)
        } else {
            reps = try container.decode(String.self, forKey: .reps)
        }
    }

    // ✅ Custom encoding (en caso de que necesites enviar datos de vuelta)
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
    let weight: Double
    let reps: Int
}

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError(String)
    case unauthorized
    case invalidRequest
    case serverError(Int)
    
    var localizedDescription: String {
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
        case .invalidRequest:
            return "Invalid request parameters"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

struct EmptyResponse: Codable {}

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
