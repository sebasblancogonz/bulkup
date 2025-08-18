//
//  APIService.swift
//  bulkup
//
//  Created by sebastian.blanco on 17/8/25.
//
import Foundation

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

class APIService: ObservableObject {
    static let shared = APIService()
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.timeout
        config.timeoutIntervalForResource = APIConfig.timeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Método genérico para requests
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        
        guard let url = URL(string: "\(APIConfig.baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Headers por defecto
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Headers adicionales
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Token de autenticación si existe
        if let token = await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Respuesta inválida")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                throw APIError.unauthorized
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            guard !data.isEmpty else {
                throw APIError.noData
            }
            
            // Log para debugging (remover en producción)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return try decoder.decode(T.self, from: data)
            
        } catch {
            if error is APIError {
                throw error
            } else if error is DecodingError {
                print("Decoding error: \(error)")
                throw APIError.decodingError
            } else {
                print("Network error: \(error)")
                throw APIError.networkError(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Método para requests con cuerpo JSON
    func requestWithBody<T: Codable, U: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: U
    ) async throws -> T {
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(body)
        
        return try await request(endpoint: endpoint, method: method, body: jsonData)
    }
    
    // MARK: - Obtener token de autenticación (implementar según tu sistema)
    private func getAuthToken() async -> String? {
        // Aquí obtienes el token de KeyChain, UserDefaults, etc.
        return UserDefaults.standard.string(forKey: "auth_token")
    }
}
