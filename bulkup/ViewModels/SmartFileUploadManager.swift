import Foundation

// MARK: - Processing Status Models
struct FileProcessingResponse: Codable {
    let success: Bool
    let processId: String
    let message: String
}

// MARK: - Smart File Upload Manager
/// Shared upload progress + timeout state. Lives as an ObservableObject because
/// the create views update progress and cancel the timeout from inside
/// NotificationCenter closures, where `@State` value types are frozen by struct
/// capture — a reference type is the only thing those closures can mutate.
@MainActor
class SmartFileUploadManager: ObservableObject {
    static let shared = SmartFileUploadManager()

    @Published var processingProgress = ""
    @Published var fileName = ""
    /// Flips to true when processing exceeds `processingTimeout`. Views observe
    /// this and surface an error instead of spinning forever (e.g. if the
    /// completion notification is never delivered).
    @Published var timedOut = false

    private var timeoutTask: Task<Void, Never>?
    private let processingTimeout: TimeInterval = 120 // 2 minutes

    private init() {}

    /// Start (or restart) the watchdog. Call when processing begins.
    func startTimeout() {
        timeoutTask?.cancel()
        timedOut = false
        timeoutTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.processingTimeout * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.timedOut = true
        }
    }

    /// Cancel the watchdog. Safe to call from a frozen-`@State` closure since
    /// `self` is a reference type.
    func cancelTimeout() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }

    func reset() {
        cancelTimeout()
        processingProgress = ""
        fileName = ""
        timedOut = false
    }
}

// MARK: - Upload
extension SmartFileUploadManager {
    /// Upload a PDF document (security-scoped URL) to /process-file-smart.
    nonisolated func uploadFile(
        at fileURL: URL,
        fileName: String,
        planName: String,
        userId: String,
        language: String,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> FileProcessingResponse {
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw FileUploadError.accessDenied
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: fileURL)
        return try await uploadToServer(
            fileData: data, fileName: fileName, planName: planName, mimeType: "application/pdf",
            userId: userId, language: language, startDate: startDate, endDate: endDate
        )
    }

    /// Upload a JPEG image to /process-file-smart.
    nonisolated func uploadImage(
        _ imageData: Data,
        fileName: String,
        planName: String,
        userId: String,
        language: String,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> FileProcessingResponse {
        try await uploadToServer(
            fileData: imageData, fileName: fileName, planName: planName, mimeType: "image/jpeg",
            userId: userId, language: language, startDate: startDate, endDate: endDate
        )
    }

    /// Builds and sends the multipart POST shared by every upload path.
    /// `fileName` keeps a real extension (drives server-side type detection);
    /// `planName` is the clean user-facing name (no extension).
    nonisolated private func uploadToServer(
        fileData: Data,
        fileName: String,
        planName: String,
        mimeType: String,
        userId: String,
        language: String,
        startDate: Date?,
        endDate: Date?
    ) async throws -> FileProcessingResponse {
        guard let url = URL(string: "\(APIConfig.baseURL)/process-file-smart") else {
            throw FileUploadError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        // Same auth scheme as APIService: Bearer token from UserDefaults.
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append(
                "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!
            )
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        appendField("userId", userId)
        appendField("planName", planName)
        appendField("language", language)

        if let startDate, let endDate {
            let formatter = ISO8601DateFormatter()
            appendField("startDate", formatter.string(from: startDate))
            appendField("endDate", formatter.string(from: endDate))
        }

        // file part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n"
                .data(using: .utf8)!
        )
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            throw FileUploadError.serverError(
                (response as? HTTPURLResponse)?.statusCode ?? 0
            )
        }

        let uploadResponse = try JSONDecoder().decode(
            FileProcessingResponse.self,
            from: responseData
        )

        guard uploadResponse.success else {
            throw FileUploadError.uploadFailed(uploadResponse.message)
        }

        return uploadResponse
    }
}

// MARK: - Error Types
enum FileUploadError: LocalizedError {
    case accessDenied
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "No se pudo acceder al archivo"
        case .invalidURL:
            return "URL del servidor inválida"
        case .invalidResponse:
            return "Respuesta del servidor inválida"
        case .serverError(let code):
            return "Error del servidor: \(code)"
        case .uploadFailed(let message):
            return "Error en la subida: \(message)"
        }
    }
}
