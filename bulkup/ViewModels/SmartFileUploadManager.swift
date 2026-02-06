import Combine
import Foundation

// MARK: - Processing Status Models
struct FileProcessingResponse: Codable {
    let success: Bool
    let processId: String
    let message: String
}

// MARK: - Smart File Upload Manager
@MainActor
class SmartFileUploadManager: ObservableObject {
    static let shared = SmartFileUploadManager()

    // UI State
    @Published var isLoading = false
    @Published var processingProgress = ""
    @Published var fileName = ""
    @Published var detectedType: FileType = .unknown
    @Published var error: String?
    @Published var showSuccessAlert = false
    @Published var successMessage = ""

    // WebSocket integration
    @Published var isWebSocketConnected = false
    private var cancellables = Set<AnyCancellable>()
    private var currentProcessId: String?
    private var processingTimeoutTask: Task<Void, Never>?
    private let processingTimeout: TimeInterval = 120 // 2 minutes

    private init() {
        setupWebSocketObserver()
    }

    private func setupWebSocketObserver() {
        // Observe WebSocket connection state
        GotifyWebSocketManager.shared.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isWebSocketConnected = connected
            }
            .store(in: &cancellables)

        // Listen for Gotify notifications
        NotificationCenter.default.publisher(
            for: NSNotification.Name("GotifyNotificationReceived")
        )
        .compactMap { $0.object as? GotifyNotification }
        .sink { [weak self] notification in
            self?.handleGotifyNotification(notification)
        }
        .store(in: &cancellables)
    }

    private func handleGotifyNotification(_ notification: GotifyNotification) {
        guard let extras = notification.extras,
            let processId = extras.processId,
            processId == currentProcessId
        else {
            return
        }

        switch extras.status {
        case "processing":
            processingProgress = "Procesando archivo..."

        case "analyzing":
            processingProgress = "Analizando contenido..."

        case "completed":
            processingTimeoutTask?.cancel()
            handleProcessingCompleted(extras: extras)

        case "failed":
            processingTimeoutTask?.cancel()
            handleProcessingFailed(error: extras.error)

        default:
            break
        }
    }

    private func startProcessingTimeout() {
        processingTimeoutTask?.cancel()
        processingTimeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(processingTimeout * 1_000_000_000))
            guard !Task.isCancelled else { return }
            isLoading = false
            currentProcessId = nil
            error = "El procesamiento tardó demasiado. Intenta de nuevo."
        }
    }

    private func handleProcessingCompleted(extras: GotifyExtras) {
        isLoading = false
        currentProcessId = nil

        if let detectedType = extras.detectedType {
            self.detectedType = detectedType == "diet" ? .diet : .training

            if detectedType == "diet" {
                successMessage = "Plan de dieta cargado exitosamente"
            } else {
                successMessage = "Plan de entrenamiento cargado exitosamente"
            }

            showSuccessAlert = true
        }
    }

    private func handleProcessingFailed(error: String?) {
        isLoading = false
        currentProcessId = nil
        self.error = error ?? "Error desconocido en el procesamiento"
    }

    func uploadFile(
        fileURL: URL,
        userId: String,
        dietManager: DietManager,
        trainingManager: TrainingManager
    ) async {
        await MainActor.run {
            isLoading = true
            fileName = fileURL.lastPathComponent
            processingProgress = "Subiendo archivo..."
            error = nil
            detectedType = .unknown
        }

        // Ensure WebSocket connection
        if !isWebSocketConnected {
            GotifyWebSocketManager.shared.connect(userId: userId)
        }

        do {
            // Start accessing the file
            guard fileURL.startAccessingSecurityScopedResource() else {
                throw FileUploadError.accessDenied
            }

            defer {
                fileURL.stopAccessingSecurityScopedResource()
            }

            // Read file data
            let fileData = try Data(contentsOf: fileURL)

            // Upload file
            let processId = try await uploadFileToServer(
                fileData: fileData,
                fileName: fileName,
                userId: userId
            )

            self.currentProcessId = processId
            self.processingProgress =
                "Archivo subido, iniciando procesamiento..."
            startProcessingTimeout()

        } catch {
            self.isLoading = false
            self.error = error.localizedDescription
        }
    }

    private func uploadFileToServer(
        fileData: Data,
        fileName: String,
        userId: String
    ) async throws -> String {

        guard let url = URL(string: "\(APIConfig.baseURL)/process-file-smart") else {
            throw FileUploadError.invalidURL
        }

        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var data = Data()

        // Add userId field
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(
                using: .utf8
            )!
        )
        data.append("\(userId)\r\n".data(using: .utf8)!)

        // Add file data
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n"
                .data(using: .utf8)!
        )
        data.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = data

        let (responseData, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileUploadError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw FileUploadError.serverError(httpResponse.statusCode)
        }

        let uploadResponse = try JSONDecoder().decode(
            FileProcessingResponse.self,
            from: responseData
        )

        guard uploadResponse.success else {
            throw FileUploadError.uploadFailed(uploadResponse.message)
        }

        return uploadResponse.processId
    }

    func reset() {
        isLoading = false
        processingProgress = ""
        fileName = ""
        detectedType = .unknown
        error = nil
        showSuccessAlert = false
        successMessage = ""
        currentProcessId = nil
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
