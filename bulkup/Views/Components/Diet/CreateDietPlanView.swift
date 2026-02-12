//
//  CreateDietPlanView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 9/2/26.
//

import SwiftUI

struct CreateDietPlanView: View {
    @EnvironmentObject var dietManager: DietManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var planName = ""
    @State private var showingFilePicker = false
    @State private var isProcessingFile = false
    @State private var errorMessage: String?
    @State private var processId: String?
    @State private var notificationObserver: NSObjectProtocol?
    @State private var showingErrorAlert = false

    @ObservedObject private var uploadManager = SmartFileUploadManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green.opacity(0.2), .green.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 36))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text("Subir Plan de Dieta")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Sube un PDF con tu plan de alimentación y la IA lo procesará automáticamente")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 8)

                    // Plan Name
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nombre del Plan")
                            .font(.headline)
                            .fontWeight(.semibold)

                        TextField("Ej: Dieta Volumen 2026", text: $planName)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                    }

                    // Upload Button
                    Button(action: {
                        showingFilePicker = true
                    }) {
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 2, dash: [8])
                                    )
                                    .foregroundColor(.green.opacity(0.4))
                                    .frame(height: 160)

                                VStack(spacing: 12) {
                                    Image(systemName: "arrow.up.doc.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.green)

                                    Text("Seleccionar PDF")
                                        .font(.headline)
                                        .foregroundColor(.green)

                                    Text("Toca para elegir tu archivo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .disabled(planName.isEmpty)
                    .opacity(planName.isEmpty ? 0.5 : 1.0)

                    if planName.isEmpty {
                        Text("Escribe un nombre para el plan antes de subir el archivo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Features Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("La IA detectará automáticamente:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        featureRow(icon: "fork.knife", text: "Comidas y horarios")
                        featureRow(icon: "list.bullet", text: "Ingredientes y cantidades")
                        featureRow(icon: "pills.fill", text: "Suplementación")
                        featureRow(icon: "calendar", text: "Planificación semanal o por fases")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )

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
            .navigationTitle("Nueva Dieta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .disabled(isProcessingFile)
            .overlay {
                if isProcessingFile {
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
        .alert("Error al procesar", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Error desconocido")
        }
        .onAppear {
            setupNotificationObserver()
            if let userId = authManager.user?.id {
                GotifyWebSocketManager.shared.connect(userId: userId)
            }
        }
        .onDisappear {
            cleanupNotifications()
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
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
                        Text("Procesando con IA...")
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
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.5))
                )
            }
    }

    // MARK: - File Handling

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            processDietFile(url)
        case .failure(let error):
            errorMessage = "Error al seleccionar archivo: \(error.localizedDescription)"
        }
    }

    private func processDietFile(_ url: URL) {
        guard let userId = authManager.user?.id else {
            errorMessage = "Usuario no autenticado"
            return
        }

        isProcessingFile = true
        errorMessage = nil
        uploadManager.processingProgress = "Subiendo archivo..."
        uploadManager.fileName = url.lastPathComponent

        Task {
            do {
                let response = try await uploadFileToServer(
                    fileURL: url,
                    fileName: planName.isEmpty ? url.lastPathComponent : "\(planName).pdf",
                    userId: userId
                )

                processId = response.processId

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

        var data = Data()

        // userId
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!
        )
        data.append("\(userId)\r\n".data(using: .utf8)!)

        // planName
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"planName\"\r\n\r\n".data(using: .utf8)!
        )
        data.append("\(fileName)\r\n".data(using: .utf8)!)

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

    // MARK: - Notification Handling

    private func setupNotificationObserver() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GotifyNotificationReceived"),
            object: nil,
            queue: .main
        ) { [self] notification in
            guard let gotifyNotification = notification.object as? GotifyNotification else {
                return
            }

            print("[Diet] Received notification - title: \(gotifyNotification.title), status=\(gotifyNotification.extras?.status ?? "nil")")

            // Note: Don't rely on @State vars (processId, isProcessingFile) here -
            // they are captured by value when the closure is created and won't update.
            // Use the class-based uploadManager instead.
            if let extras = gotifyNotification.extras, extras.status != nil {
                handleProcessingNotification(extras: extras)
            } else if gotifyNotification.title.contains("completado") {
                handleProcessingCompleted(extras: GotifyExtras.empty)
            }
        }
    }

    private func handleProcessingNotification(extras: GotifyExtras) {
        switch extras.status {
        case "processing":
            uploadManager.processingProgress = "Analizando estructura del PDF..."

        case "analyzing":
            uploadManager.processingProgress = "Extrayendo comidas y nutrición..."

        case "completed":
            handleProcessingCompleted(extras: extras)

        case "failed":
            handleProcessingFailed(error: extras.error)

        default:
            break
        }
    }

    private func handleProcessingCompleted(extras: GotifyExtras) {
        print("[Diet] handleProcessingCompleted called")
        print("[Diet] authManager.user?.id = \(authManager.user?.id ?? "nil")")

        Task {
            if let userId = authManager.user?.id {
                print("[Diet] Loading active diet plan for user: \(userId)")
                await dietManager.loadActiveDietPlan(userId: userId)
                print("[Diet] Diet plan loaded, dietData count: \(dietManager.dietData.count)")
            } else {
                print("[Diet] WARNING: No user ID available, skipping diet load")
            }

            await MainActor.run {
                isProcessingFile = false
                uploadManager.reset()
                dismiss()
            }
        }
    }

    private func handleProcessingFailed(error: String?) {
        isProcessingFile = false
        errorMessage = error ?? "Error al procesar el archivo"
        showingErrorAlert = true
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
