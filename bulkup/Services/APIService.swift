//
//  APIService.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
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
    func request<T: Codable>(
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
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Respuesta inválida")
            }

            switch httpResponse.statusCode {
            case 200...299:
                break
            case 404:
                throw APIError.notFound
            case 401:
                throw APIError.unauthorized
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                // Crear un formatter personalizado
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)

                if let date = formatter.date(from: dateString) {
                    return date
                }

                // Backup formatter sin milisegundos
                let backupFormatter = DateFormatter()
                backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                backupFormatter.locale = Locale(identifier: "en_US_POSIX")
                backupFormatter.timeZone = TimeZone(secondsFromGMT: 0)

                if let date = backupFormatter.date(from: dateString) {
                    return date
                }

                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string \(dateString)"
                )
            }

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

        guard let url = URL(string: "\(APIConfig.baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // Headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Encode body
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS'Z'"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(abbreviation: "UTC")  // Importante: UTC para Z

            let dateString = formatter.string(from: date)
            try container.encode(dateString)
        }

        request.httpBody = try encoder.encode(body)

        // Token de autenticación si existe
        if let token = await getAuthToken() {
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        do {
            let (data, response) = try await session.data(for: request)
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 RAW Response from /profile PUT:")
                print(responseString)
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Respuesta inválida")
            }

            switch httpResponse.statusCode {
            case 200...299:
                break
            case 400:
                throw APIError.invalidRequest(httpResponse)
            case 401:
                throw APIError.unauthorized
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                // Crear un formatter personalizado
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)

                if let date = formatter.date(from: dateString) {
                    return date
                }

                // Backup formatter sin milisegundos
                let backupFormatter = DateFormatter()
                backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                backupFormatter.locale = Locale(identifier: "en_US_POSIX")
                backupFormatter.timeZone = TimeZone(secondsFromGMT: 0)

                if let date = backupFormatter.date(from: dateString) {
                    return date
                }

                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string \(dateString)"
                )
            }  // Añadir esta línea
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

    // MARK: - Obtener token de autenticación (implementar según tu sistema)
    private func getAuthToken() async -> String? {
        // Aquí obtienes el token de KeyChain, UserDefaults, etc.
        return UserDefaults.standard.string(forKey: "auth_token")
    }
}
