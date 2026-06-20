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
            decoder.dateDecodingStrategy = .custom { dec in
                let container = try dec.singleValueContainer()
                let dateString = try container.decode(String.self)
                if let date = APIService.parseServerDate(dateString) {
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

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
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
        decoder.dateDecodingStrategy = .custom { dec in
            let container = try dec.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = APIService.parseServerDate(dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateString)"
            )
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error for endpoint '\(endpoint)': \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            throw APIError.decodingError
        }
    }

    // MARK: - Obtener token de autenticación (implementar según tu sistema)
    private func getAuthToken() async -> String? {
        // Aquí obtienes el token de KeyChain, UserDefaults, etc.
        return UserDefaults.standard.string(forKey: "auth_token")
    }
}

// MARK: - Robust server date parsing

extension APIService {
    /// Parses RFC3339 / ISO8601 timestamps from the Go backend, which emits
    /// variable-length fractional seconds (nanoseconds). Fixed ".SSS"
    /// DateFormatters reject those, which silently broke list decoding.
    static func parseServerDate(_ raw: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: raw) { return d }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: raw) { return d }

        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)

        // Normalize fractional seconds to 3 digits, then parse as milliseconds.
        if let range = raw.range(of: #"\.\d+"#, options: .regularExpression) {
            let digits = raw[range].dropFirst()
            let millis = String((digits + "000").prefix(3))
            let normalized = raw.replacingCharacters(in: range, with: "." + millis)
            f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let d = f.date(from: normalized) { return d }
        }

        for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd'T'HH:mm:ss"] {
            f.dateFormat = fmt
            if let d = f.date(from: raw) { return d }
        }
        return nil
    }

    #if DEBUG
    static func runDateParsingSelfCheck() {
        assert(parseServerDate("2026-06-20T10:00:00.123456789Z") != nil, "nanoseconds")
        assert(parseServerDate("2026-06-20T10:00:00Z") != nil, "no fraction")
        assert(parseServerDate("2026-06-20T10:00:00.123Z") != nil, "milliseconds")
        assert(parseServerDate("not-a-date") == nil, "invalid")
    }
    #endif
}
