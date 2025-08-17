//
//  API.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//

import Foundation
import Combine

struct APIConfig {
    static let baseURL = "https://your-backend-api.com/api" // Cambia por tu URL
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
