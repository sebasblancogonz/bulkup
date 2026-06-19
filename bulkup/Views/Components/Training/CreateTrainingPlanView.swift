//
//  CreateTrainingPlanView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 23/8/25.
//

import PhotosUI
import SwiftUI

struct CreateTrainingPlanView: View {
    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    var initialMethod: CreationMethod?

    @State private var planName = ""
    @State private var startDate = Date()
    @State private var endDate =
        Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var useCustomDates = false
    @State private var creationMethod: CreationMethod = .manual
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showingFilePicker = false
    @State private var showingTemplateSelection = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    @ObservedObject private var uploadManager = SmartFileUploadManager.shared
    @State private var isProcessingFile = false
    @State private var processId: String?
    @State private var notificationObserver: NSObjectProtocol?
    @State private var showingErrorAlert = false

    enum CreationMethod: String, CaseIterable {
        case manual = "manual"
        case upload = "upload"
        case template = "template"
        case imageUpload = "imageUpload"

        var displayName: String {
            switch self {
            case .manual: return "Crear Manualmente"
            case .upload: return "Subir Archivo"
            case .template: return "Usar Plantilla"
            case .imageUpload: return "Importar desde Imagen"
            }
        }

        var icon: String {
            switch self {
            case .manual: return "pencil.and.outline"
            case .upload: return "doc.badge.plus"
            case .template: return "doc.on.doc"
            case .imageUpload: return "photo.on.rectangle"
            }
        }

        var description: String {
            switch self {
            case .manual: return "Construye tu plan paso a paso"
            case .upload: return "Sube un PDF con tu rutina"
            case .template: return "Comienza con una plantilla"
            case .imageUpload: return "Sube una foto de tu rutina"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Plan Name Section
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Nombre del Plan")
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)

                        TextField("Ej: Fuerza Primavera 2024", text: $planName)
                            .padding(Spacing.md)
                            .background(BulkUpColors.surfaceElevated)
                            .cornerRadius(CornerRadius.small)
                            .foregroundColor(BulkUpColors.textPrimary)
                            .submitLabel(.done)
                    }

                    // Date Range Section
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            Text("Duración del Plan")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)

                            Spacer()

                            Toggle("Fechas específicas", isOn: $useCustomDates)
                                .toggleStyle(.switch)
                                .tint(BulkUpColors.training)
                        }

                        if useCustomDates {
                            VStack(spacing: Spacing.md) {
                                DatePicker(
                                    "Fecha de inicio",
                                    selection: $startDate,
                                    displayedComponents: .date
                                )
                                .foregroundColor(BulkUpColors.textPrimary)
                                DatePicker(
                                    "Fecha de fin",
                                    selection: $endDate,
                                    displayedComponents: .date
                                )
                                .foregroundColor(BulkUpColors.textPrimary)
                            }
                            .padding(.leading)
                        } else {
                            Text("Sin fechas específicas - plan indefinido")
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.textSecondary)
                                .padding(.leading)
                        }
                    }

                    // Creation Method Section
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("Método de Creación")
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)

                        VStack(spacing: Spacing.md) {
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
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.error)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(BulkUpColors.background)
            .navigationTitle("Nuevo Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(BulkUpColors.training)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Continuar") {
                        handleContinue()
                    }
                    .disabled(planName.isEmpty || isCreating)
                    .fontWeight(.semibold)
                    .foregroundColor(BulkUpColors.training)
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
        .sheet(isPresented: $showingTemplateSelection) {
            TemplateSelectionView { template in
                createPlanFromTemplate(template)
            }
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
                    processTrainingPlanImage(jpeg)
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
            if let initial = initialMethod {
                creationMethod = initial
            }
        }
        .onDisappear {
            cleanupNotifications()
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
                        if isProcessingFile {
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
                                .cornerRadius(20)
                            }
                        } else {
                            Text("Creando plan...")
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(BulkUpColors.textPrimary)
                        }
                    }
                }
                .padding(Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(BulkUpColors.surface.opacity(0.95))
                )
            }
    }

    private func handleContinue() {
        errorMessage = nil

        switch creationMethod {
        case .manual:
            createEmptyPlan()
        case .upload:
            showingFilePicker = true
        case .template:
            showingTemplateSelection = true
        case .imageUpload:
            showingPhotoPicker = true
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

                let response = try await APIService.shared.createTrainingPlan(
                    userId: userId,
                    filename: planName,
                    trainingData: emptyTrainingData,
                    planStartDate: useCustomDates ? startDate : nil,
                    planEndDate: useCustomDates ? endDate : nil
                )

                // Auto-activate the newly created plan
                try await APIService.shared.activateTrainingPlan(
                    userId: userId,
                    planId: response.planId
                )

                // Reload active plan so the hub shows it immediately
                await trainingManager.loadActiveTrainingPlan(userId: userId)

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

    private func createPlanFromTemplate(_ template: WorkoutTemplate) {
        guard let userId = authManager.user?.id else { return }

        isCreating = true

        Task {
            do {
                let response = try await APIService.shared.createTrainingPlan(
                    userId: userId,
                    filename: planName,
                    trainingData: template.trainingDays,
                    planStartDate: useCustomDates ? startDate : nil,
                    planEndDate: useCustomDates ? endDate : nil
                )

                // Auto-activate the newly created plan
                try await APIService.shared.activateTrainingPlan(
                    userId: userId,
                    planId: response.planId
                )

                // Reload active plan so the hub shows it immediately
                await trainingManager.loadActiveTrainingPlan(userId: userId)

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
        uploadManager.processingProgress = "Subiendo archivo..."
        uploadManager.fileName = url.lastPathComponent
        uploadManager.startTimeout()

        Task {
            do {
                let response = try await uploadManager.uploadFile(
                    at: url,
                    fileName: planName.isEmpty
                        ? url.lastPathComponent : "\(planName).pdf",
                    userId: userId,
                    startDate: useCustomDates ? startDate : nil,
                    endDate: useCustomDates ? endDate : nil
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

    @MainActor
    private func processTrainingPlanImage(_ imageData: Data) {
        guard let userId = authManager.user?.id else {
            errorMessage = "Usuario no autenticado"
            return
        }

        isProcessingFile = true
        errorMessage = nil
        uploadManager.processingProgress = "Subiendo imagen..."
        uploadManager.fileName = planName.isEmpty ? "training_plan.jpg" : "\(planName).jpg"
        uploadManager.startTimeout()

        Task {
            do {
                let fileName = planName.isEmpty ? "training_plan.jpg" : "\(planName).jpg"
                let response = try await uploadManager.uploadImage(
                    imageData,
                    fileName: fileName,
                    userId: userId,
                    startDate: useCustomDates ? startDate : nil,
                    endDate: useCustomDates ? endDate : nil
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

    private func setupNotificationObserver() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GotifyNotificationReceived"),
            object: nil,
            queue: .main
        ) { [self] notification in
            guard let gotifyNotification = notification.object
                as? GotifyNotification
            else {
                return
            }

            // @State (processId) is frozen at nil inside this escaping closure
            // (struct capture), so we can't filter by it — react by status like
            // the diet flow does. Otherwise completion never fires: stuck spinner.
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
        uploadManager.cancelTimeout()
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

struct CreationMethodCard: View {
    let method: CreateTrainingPlanView.CreationMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? BulkUpColors.training.opacity(0.1)
                                : BulkUpColors.surfaceElevated
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: method.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? BulkUpColors.training : BulkUpColors.textTertiary)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(LocalizedStringKey(method.displayName))
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)

                    Text(LocalizedStringKey(method.description))
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.training)
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(
                        isSelected ? BulkUpColors.training : BulkUpColors.textTertiary.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(BulkUpColors.surface)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
