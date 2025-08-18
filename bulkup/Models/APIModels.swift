//
//  API.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import Foundation
import Combine

struct APIConfig {
    static let baseURL = "http://localhost:8080" // Cambia por tu URL
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
        let instructions: [String]? // <-- Optional now
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
