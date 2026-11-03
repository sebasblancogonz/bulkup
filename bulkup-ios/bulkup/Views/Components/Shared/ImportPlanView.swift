//
//  ImportPlanView.swift
//  bulkup
//
//  One import for both kinds of plan. You name it and upload the PDF or the
//  photo; the backend reads it and says whether it was a routine or a diet
//  (`detectedType` on the completion notification), and the app opens that tab.
//

import PhotosUI
import SwiftUI

struct ImportPlanView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var uploadManager = SmartFileUploadManager.shared

    enum Phase: Equatable {
        case idle
        case reading
        case failed(String)
    }

    @State private var phase: Phase = .idle
    @State private var planName = ""
    @State private var useDates = false
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .weekOfYear, value: 8, to: Date()) ?? Date()
    @State private var showingFilePicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    /// The server's id for this upload; completion messages for other uploads are ignored.
    @State private var processId: String?
    @FocusState private var nameFocused: Bool

    #if DEBUG
    /// Design harness: render a given phase without a network.
    var previewPhase: Phase? = nil
    var previewName: String = ""
    #endif

    private var canUpload: Bool {
        !planName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            BulkUpGround()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header

                    switch phase {
                    case .idle:
                        form
                    case .reading:
                        readingBlock
                    case .failed(let message):
                        failedBlock(message)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(BulkUpColors.background)
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { upload(fileURL: url) }
            case .failure(let error):
                phase = .failed(error.localizedDescription)
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    // Library photos are usually HEIC; the server expects a real JPEG.
                    let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.85) ?? data
                    upload(imageData: jpeg)
                }
                selectedPhotoItem = nil
            }
        }
        .onChange(of: uploadManager.timedOut) { _, timedOut in
            if timedOut, phase == .reading {
                uploadManager.reset()
                phase = .failed(NSLocalizedString("Ha tardado demasiado. Vuelve a intentarlo.", comment: ""))
            }
        }
        .onAppear {
            #if DEBUG
            if let previewPhase {
                phase = previewPhase
                planName = previewName
                if case .reading = previewPhase {
                    uploadManager.processingProgress = NSLocalizedString("Sacando los datos del plan…", comment: "")
                    uploadManager.fileName = "rutina-octubre.pdf"
                }
                return
            }
            #endif
            if let userId = authManager.user?.id {
                GotifyWebSocketManager.shared.connect(userId: userId)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            #if DEBUG
            if previewPhase != nil { return }
            #endif
            switch newPhase {
            case .background:
                GotifyWebSocketManager.shared.disconnect()
            case .active:
                if let userId = authManager.user?.id {
                    GotifyWebSocketManager.shared.connect(userId: userId)
                }
            default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GotifyNotificationReceived"))) { notification in
            handle(notification)
        }
        .onDisappear { cleanupNotifications() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("Importar un plan")
                    .titleVoice(.title)
                    .foregroundColor(BulkUpColors.textPrimary)
                Spacer(minLength: Spacing.md)
                if phase != .reading {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancelar")
                            .font(.system(.footnote, weight: .semibold))
                            .foregroundColor(BulkUpColors.textSecondary)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            if phase == .idle {
                Text("Sube el PDF o la foto que te dio tu entrenador. Rutina o dieta, da igual: lo detectamos.")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
            }
        }
    }

    // MARK: - Form

    private var form: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Nombre del plan")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                TextField("Volumen otoño", text: $planName)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)
                    .submitLabel(.done)
                    .focused($nameFocused)
                    .tint(BulkUpColors.accentText)
                    .padding(.horizontal, Spacing.md)
                    .frame(minHeight: 44)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .strokeBorder(BulkUpColors.accent, lineWidth: nameFocused ? 1.5 : 0)
                    )
                    .accessibilityLabel("Nombre del plan")
            }

            datesSlab

            VStack(alignment: .leading, spacing: Spacing.sm) {
                VStack(spacing: 0) {
                    PlanActionRow(glyph: "doc", title: "Elegir PDF", subtitle: "Desde Archivos") {
                        nameFocused = false
                        showingFilePicker = true
                    }
                    PlanActionRow(glyph: "photo", title: "Elegir foto", subtitle: "Desde Fotos", showsSeparator: false) {
                        nameFocused = false
                        showingPhotoPicker = true
                    }
                }
                .slab()
                .disabled(!canUpload)
                .opacity(canUpload ? 1 : 0.5)
                .animation(.easeOut(duration: 0.2), value: canUpload)

                if !canUpload {
                    Text("Ponle nombre antes de subir el archivo.")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }

            Text("Leemos días, ejercicios, series y descansos; o comidas, cantidades y suplementos. Suele tardar menos de un minuto.")
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textTertiary)
        }
    }

    private var datesSlab: some View {
        VStack(spacing: 0) {
            SlabRow(showsSeparator: useDates, minHeight: 52) {
                Toggle(isOn: $useDates.animation(.easeOut(duration: 0.2))) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Con fechas de inicio y fin")
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundColor(BulkUpColors.textPrimary)
                        Text("Solo cuenta para rutinas")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                }
                .tint(BulkUpColors.accent)
            }
            if useDates {
                SlabRow(minHeight: 48) {
                    DatePicker("Inicio", selection: $startDate, displayedComponents: .date)
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textPrimary)
                        .tint(BulkUpColors.accentText)
                }
                SlabRow(showsSeparator: false, minHeight: 48) {
                    DatePicker("Fin", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textPrimary)
                        .tint(BulkUpColors.accentText)
                }
            }
        }
        .slab()
    }

    // MARK: - Reading / failed

    private var readingBlock: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(BulkUpColors.accent)
                .padding(.bottom, Spacing.sm)

            Text("Leyendo tu plan")
                .titleVoice(.title2)
                .foregroundColor(BulkUpColors.textPrimary)

            Text(uploadManager.processingProgress.isEmpty
                 ? NSLocalizedString("Subiendo el archivo…", comment: "")
                 : uploadManager.processingProgress)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)

            if !uploadManager.fileName.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "doc")
                        .font(.system(.caption, weight: .medium))
                    Text(uploadManager.fileName)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textTertiary)
            }

            Text("Puedes cerrar esto; el plan se guarda igual y te avisamos cuando esté.")
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.sm)

            Button {
                dismiss()
            } label: {
                Text("Seguir en segundo plano")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .pressable()
            .padding(.top, Spacing.md)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(.vertical, Spacing.lg)
    }

    private func failedBlock(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("No hemos podido leerlo")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                Text(message)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.warning)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .slab()

            Button {
                withAnimation(.easeOut(duration: 0.2)) { phase = .idle }
            } label: {
                Text("Reintentar")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .pressable()
        }
    }

    // MARK: - Upload

    private func upload(fileURL: URL) {
        guard let userId = authManager.user?.id else {
            phase = .failed(NSLocalizedString("Usuario no autenticado", comment: ""))
            return
        }
        beginReading(fileName: fileURL.lastPathComponent)
        let name = planName.trimmingCharacters(in: .whitespaces)
        let language = LanguageManager.shared.resolvedCode
        let (start, end) = useDates ? (startDate, endDate) : (nil, nil)
        Task {
            do {
                let response = try await uploadManager.uploadFile(
                    at: fileURL, fileName: fileURL.lastPathComponent, planName: name,
                    userId: userId, language: language, startDate: start, endDate: end
                )
                await MainActor.run { processId = response.processId }
            } catch {
                await MainActor.run { fail(error.localizedDescription) }
            }
        }
    }

    private func upload(imageData: Data) {
        guard let userId = authManager.user?.id else {
            phase = .failed(NSLocalizedString("Usuario no autenticado", comment: ""))
            return
        }
        let name = planName.trimmingCharacters(in: .whitespaces)
        beginReading(fileName: "\(name).jpg")
        let language = LanguageManager.shared.resolvedCode
        let (start, end) = useDates ? (startDate, endDate) : (nil, nil)
        Task {
            do {
                let response = try await uploadManager.uploadImage(
                    imageData, fileName: "plan.jpg", planName: name,
                    userId: userId, language: language, startDate: start, endDate: end
                )
                await MainActor.run { processId = response.processId }
            } catch {
                await MainActor.run { fail(error.localizedDescription) }
            }
        }
    }

    private func beginReading(fileName: String) {
        nameFocused = false
        processId = nil
        uploadManager.processingProgress = NSLocalizedString("Subiendo el archivo…", comment: "")
        uploadManager.fileName = fileName
        uploadManager.startTimeout()
        withAnimation(.easeOut(duration: 0.25)) { phase = .reading }
    }

    private func fail(_ message: String) {
        uploadManager.reset()
        withAnimation(.easeOut(duration: 0.2)) { phase = .failed(message) }
    }

    // MARK: - Completion (Gotify over websocket)

    private func handle(_ notification: Notification) {
        guard phase == .reading, let gotify = notification.object as? GotifyNotification,
              let extras = gotify.extras, let status = extras.status else { return }
        // Only this upload: a replayed message from an earlier import must not
        // land the wrong plan or a false failure. The upload response and the
        // notification carry the same id (the processed file's ObjectID).
        if let mine = processId, let theirs = extras.processId, mine != theirs { return }
        switch status {
        case "processing":
            uploadManager.processingProgress = NSLocalizedString("Leyendo la estructura…", comment: "")
        case "analyzing":
            uploadManager.processingProgress = NSLocalizedString("Sacando los datos del plan…", comment: "")
        case "completed":
            complete(detectedType: extras.detectedType ?? extras.fileType)
        case "failed":
            fail(extras.error ?? NSLocalizedString("Error al procesar el archivo", comment: ""))
        default:
            break
        }
    }

    private func complete(detectedType: String?) {
        uploadManager.cancelTimeout()
        let kind = detectedType?.lowercased()
        Task {
            if let userId = authManager.user?.id {
                switch kind {
                case "training", "workout":
                    await TrainingManager.shared.loadActiveTrainingPlan(userId: userId)
                case "diet":
                    await DietManager.shared.loadActiveDietPlan(userId: userId)
                default:
                    await TrainingManager.shared.loadActiveTrainingPlan(userId: userId)
                    await DietManager.shared.loadActiveDietPlan(userId: userId)
                }
            }
            await MainActor.run {
                uploadManager.reset()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                // Switch the tab first, then let the sheet go on the next turn:
                // dismissing and switching in one pass can leave the sheet stuck.
                switch kind {
                case "training", "workout":
                    NotificationCenter.default.post(name: .navigateToTraining, object: nil)
                case "diet":
                    NotificationCenter.default.post(name: .navigateToDiet, object: nil)
                default:
                    break
                }
                DispatchQueue.main.async { dismiss() }
            }
        }
    }

    private func cleanupNotifications() {
        #if DEBUG
        if previewPhase != nil { return }
        #endif
        GotifyWebSocketManager.shared.disconnect()
    }
}
