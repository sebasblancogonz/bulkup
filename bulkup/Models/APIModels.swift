//
//  API.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import Combine
import Foundation

struct APIConfig {
    static let baseURL = "http://localhost:8080"  // Cambia por tu URL
    static let timeout: TimeInterval = 30.0
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

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(String)
    case serverError(Int)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .noData:
            return "No se recibieron datos"
        case .decodingError:
            return "Error al procesar los datos"
        case .networkError(let message):
            return "Error de red: \(message)"
        case .serverError(let code):
            return "Error del servidor: \(code)"
        case .unauthorized:
            return "No autorizado"
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
