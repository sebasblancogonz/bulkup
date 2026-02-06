//
//  CreateTrainingPlanView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 23/8/25.
//

import SwiftUI

struct CreateTrainingPlanView: View {
    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var planName = ""
    @State private var startDate = Date()
    @State private var endDate =
        Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var useCustomDates = false
    @State private var creationMethod: CreationMethod = .manual
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showingFilePicker = false

    @ObservedObject private var uploadManager = SmartFileUploadManager.shared
    @State private var isProcessingFile = false
    @State private var processId: String?
    @State private var notificationObserver: NSObjectProtocol?

    enum CreationMethod: String, CaseIterable {
        case manual = "manual"
        case upload = "upload"
        case template = "template"

        var displayName: String {
            switch self {
            case .manual: return "Crear Manualmente"
            case .upload: return "Subir Archivo"
            case .template: return "Usar Plantilla"
            }
        }

        var icon: String {
            switch self {
            case .manual: return "pencil.and.outline"
            case .upload: return "doc.badge.plus"
            case .template: return "doc.on.doc"
            }
        }

        var description: String {
            switch self {
            case .manual: return "Construye tu plan paso a paso"
            case .upload: return "Sube un PDF con tu rutina"
            case .template: return "Comienza con una plantilla"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Plan Name Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nombre del Plan")
                            .font(.headline)
                            .fontWeight(.semibold)

                        TextField("Ej: Fuerza Primavera 2024", text: $planName)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                    }

                    // Date Range Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Duración del Plan")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Spacer()

                            Toggle("Fechas específicas", isOn: $useCustomDates)
                                .toggleStyle(.switch)
                        }

                        if useCustomDates {
                            VStack(spacing: 12) {
                                DatePicker(
                                    "Fecha de inicio",
                                    selection: $startDate,
                                    displayedComponents: .date
                                )
                                DatePicker(
                                    "Fecha de fin",
                                    selection: $endDate,
                                    displayedComponents: .date
                                )
                            }
                            .padding(.leading)
                        } else {
                            Text("Sin fechas específicas - plan indefinido")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.leading)
                        }
                    }

                    // Creation Method Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Método de Creación")
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(spacing: 12) {
                            ForEach(CreationMethod.allCases, id: \.self) {
                                method in
                                CreationMethodCard(
                                    method: method,
                                    isSelected: creationMethod == method
                                ) {
                                    creationMethod = method
                                }
                            }
                        }
                    }

                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("Nuevo Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continuar") {
                        handleContinue()
                    }
                    .disabled(planName.isEmpty || isCreating)
                    .fontWeight(.semibold)
                }
            }
            .disabled(isCreating || isProcessingFile)
            .overlay {
                if isCreating || isProcessingFile {
                    processingOverlay
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .onAppear {
            setupNotificationObserver()
        }
        .onDisappear {
            cleanupNotifications()
        }
    }

    private var processingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)

                    VStack(spacing: 8) {
                        if isProcessingFile {
                            Text("🧠 Procesando con IA...")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(uploadManager.processingProgress)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            if !uploadManager.fileName.isEmpty {
                                HStack {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(uploadManager.fileName)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(20)
                            }
                        } else {
                            Text("Creando plan...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.5))
                )
            }
    }

    private func handleContinue() {
        errorMessage = nil

        switch creationMethod {
        case .manual:
            // For now, create an empty plan - you'd implement a manual creation flow
            createEmptyPlan()
        case .upload:
            showingFilePicker = true
        case .template:
            // For now, just create an empty plan - you'd implement template selection
            createEmptyPlan()
        }
    }

    private func createEmptyPlan() {
        guard let userId = authManager.user?.id else { return }

        isCreating = true

        Task {
            do {
                let emptyTrainingData: [ServerTrainingDay] = [
                    ServerTrainingDay(
                        day: "Lunes",
                        workoutName: "Día 1",
                        output: []
                    ),
                    ServerTrainingDay(
                        day: "Miércoles",
                        workoutName: "Día 2",
                        output: []
                    ),
                    ServerTrainingDay(
                        day: "Viernes",
                        workoutName: "Día 3",
                        output: []
                    ),
                ]

                let _ = try await APIService.shared.createTrainingPlan(
                    userId: userId,
                    filename: planName,
                    trainingData: emptyTrainingData,
                    planStartDate: useCustomDates ? startDate : nil,
                    planEndDate: useCustomDates ? endDate : nil
                )

                await MainActor.run {
                    isCreating = false
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // Handle PDF processing - integrate with your existing file processing logic
            processTrainingPlanFile(url)
        case .failure(let error):
            errorMessage =
                "Error al seleccionar archivo: \(error.localizedDescription)"
        }
    }

    private func processTrainingPlanFile(_ url: URL) {
        guard let userId = authManager.user?.id else {
            errorMessage = "Usuario no autenticado"
            return
        }

        isProcessingFile = true
        errorMessage = nil

        // Conectar WebSocket para recibir notificaciones
        GotifyWebSocketManager.shared.connect(userId: userId)

        Task {
            do {
                // Subir archivo al servidor
                let response = try await uploadFileToServer(
                    fileURL: url,
                    fileName: planName.isEmpty
                        ? url.lastPathComponent : "\(planName).pdf",
                    userId: userId
                )

                processId = response.processId

                // El procesamiento continúa de forma asíncrona
                // Las notificaciones llegarán vía WebSocket

            } catch {
                await MainActor.run {
                    isProcessingFile = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func uploadFileToServer(
        fileURL: URL,
        fileName: String,
        userId: String
    ) async throws -> FileProcessingResponse {
        guard fileURL.startAccessingSecurityScopedResource() else {
            throw FileUploadError.accessDenied
        }

        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }

        let fileData = try Data(contentsOf: fileURL)

        guard let url = URL(string: "\(APIConfig.baseURL)/process-file-smart")
        else {
            throw FileUploadError.invalidURL
        }

        // Crear multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var data = Data()

        // userId
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(
                using: .utf8
            )!
        )
        data.append("\(userId)\r\n".data(using: .utf8)!)

        // planName
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"planName\"\r\n\r\n".data(
                using: .utf8
            )!
        )
        data.append("\(fileName)\r\n".data(using: .utf8)!)

        // dates if needed
        if useCustomDates {
            let formatter = ISO8601DateFormatter()

            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append(
                "Content-Disposition: form-data; name=\"startDate\"\r\n\r\n"
                    .data(using: .utf8)!
            )
            data.append(
                "\(formatter.string(from: startDate))\r\n".data(using: .utf8)!
            )

            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append(
                "Content-Disposition: form-data; name=\"endDate\"\r\n\r\n".data(
                    using: .utf8
                )!
            )
            data.append(
                "\(formatter.string(from: endDate))\r\n".data(using: .utf8)!
            )
        }

        // file
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

    private func setupNotificationObserver() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GotifyNotificationReceived"),
            object: nil,
            queue: .main
        ) { [self] notification in
            guard
                let gotifyNotification = notification.object
                    as? GotifyNotification,
                let extras = gotifyNotification.extras,
                let notificationProcessId = extras.processId,
                notificationProcessId == self.processId
            else {
                return
            }

            handleProcessingNotification(extras: extras)
        }
    }

    private func handleProcessingNotification(extras: GotifyExtras) {
        switch extras.status {
        case "processing":
            uploadManager.processingProgress =
                "Analizando estructura del PDF..."

        case "analyzing":
            uploadManager.processingProgress =
                "Extrayendo ejercicios y rutinas..."

        case "completed":
            handleProcessingCompleted(extras: extras)

        case "failed":
            handleProcessingFailed(error: extras.error)

        default:
            break
        }
    }

    private func handleProcessingCompleted(extras: GotifyExtras) {
        Task {
            // Recargar los planes de entrenamiento
            if let userId = authManager.user?.id {
                await trainingManager.loadActiveTrainingPlan(userId: userId)
            }

            await MainActor.run {
                isProcessingFile = false
                uploadManager.reset()

                // Mostrar éxito y cerrar
                dismiss()
            }
        }
    }

    private func handleProcessingFailed(error: String?) {
        isProcessingFile = false
        errorMessage = error ?? "Error al procesar el archivo"
        uploadManager.reset()
    }

    private func cleanupNotifications() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
        GotifyWebSocketManager.shared.disconnect()
    }

}

struct CreationMethodCard: View {
    let method: CreateTrainingPlanView.CreationMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? Color.blue.opacity(0.1)
                                : Color.gray.opacity(0.1)
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: method.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .blue : .gray)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(method.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(method.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.blue : Color.gray.opacity(0.3),
                        lineWidth: 2
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
