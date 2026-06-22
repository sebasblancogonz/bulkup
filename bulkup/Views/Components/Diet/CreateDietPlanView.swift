//
//  CreateDietPlanView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 9/2/26.
//

import PhotosUI
import SwiftUI

struct CreateDietPlanView: View {
    @EnvironmentObject var dietManager: DietManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var planName = ""
    @State private var showingFilePicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessingFile = false
    @State private var errorMessage: String?
    @State private var processId: String?
    @State private var notificationObserver: NSObjectProtocol?
    @State private var showingErrorAlert = false

    @ObservedObject private var uploadManager = SmartFileUploadManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [BulkUpColors.diet.opacity(0.2), BulkUpColors.diet.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Image(systemName: "doc.viewfinder")
                                .font(.system(size: 36))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [BulkUpColors.diet, BulkUpColors.diet.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text("Subir Plan de Dieta")
                            .font(BulkUpFont.sectionHeader())
                            .foregroundColor(BulkUpColors.textPrimary)

                        Text("Sube un PDF o foto con tu plan de alimentación y la IA lo procesará automáticamente")
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, Spacing.sm)

                    // Plan Name
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Nombre del Plan")
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)

                        TextField("Ej: Dieta Volumen 2026", text: $planName)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                    }

                    // Upload Buttons
                    AIImportUploadBoxes(
                        tint: BulkUpColors.diet,
                        onPickPDF: { showingFilePicker = true },
                        onPickImage: { showingPhotoPicker = true },
                        disabled: planName.isEmpty
                    )

                    if planName.isEmpty {
                        Text("Escribe un nombre para el plan antes de subir el archivo")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }

                    // Features Info
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("La IA detectará automáticamente:")
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.textPrimary)

                        featureRow(icon: "fork.knife", text: "Comidas y horarios")
                        featureRow(icon: "list.bullet", text: "Ingredientes y cantidades")
                        featureRow(icon: "pills.fill", text: "Suplementación")
                        featureRow(icon: "calendar", text: "Planificación semanal o por fases")
                    }
                    .flatCardStyle()

                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.error)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .background(BulkUpColors.background)
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
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    // Library photos are usually HEIC; re-encode to real JPEG so
                    // the bytes match the image/jpeg content-type the server expects.
                    let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.85) ?? data
                    await processDietImage(jpeg)
                }
            }
        }
        .alert("Error al procesar", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Error desconocido")
        }
        .onChange(of: uploadManager.timedOut) { _, timedOut in
            if timedOut {
                isProcessingFile = false
                errorMessage = "El procesamiento tardó demasiado. Intenta de nuevo."
                showingErrorAlert = true
                uploadManager.reset()
            }
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
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.diet)
                .frame(width: 24)
            Text(LocalizedStringKey(text))
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
        }
    }

    private var processingOverlay: some View {
        BulkUpColors.shadow.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(BulkUpColors.accent)

                    VStack(spacing: Spacing.sm) {
                        Text("Procesando con IA...")
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)

                        Text(uploadManager.processingProgress)
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.textSecondary)

                        if !uploadManager.fileName.isEmpty {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(BulkUpColors.textTertiary)
                                Text(uploadManager.fileName)
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textTertiary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, 6)
                            .background(BulkUpColors.textTertiary.opacity(0.2))
                            .cornerRadius(CornerRadius.xl)
                        }
                    }
                }
                .padding(Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(BulkUpColors.surface.opacity(0.9))
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
        uploadManager.startTimeout()

        Task {
            do {
                let response = try await uploadManager.uploadFile(
                    at: url,
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

    // MARK: - Image Upload

    @MainActor
    private func processDietImage(_ imageData: Data) {
        guard let userId = authManager.user?.id else {
            errorMessage = "Usuario no autenticado"
            return
        }

        isProcessingFile = true
        errorMessage = nil
        uploadManager.processingProgress = "Subiendo imagen..."
        uploadManager.fileName = planName.isEmpty ? "diet_plan.jpg" : "\(planName).jpg"
        uploadManager.startTimeout()

        Task {
            do {
                let fileName = planName.isEmpty ? "diet_plan.jpg" : "\(planName).jpg"
                let response = try await uploadManager.uploadImage(
                    imageData,
                    fileName: fileName,
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
        uploadManager.cancelTimeout()
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
        uploadManager.cancelTimeout()
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
