//
//  TrainingHubView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 23/8/25.
//

import SwiftData
import SwiftUI

struct TrainingHubView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var trainingManager: TrainingManager
    @State private var selectedView: TrainingHubSection = .active
    @State private var showingCreatePlan = false
    @State private var showingPlanEditor = false
    @State private var showingPlanLibrary = false
    @State private var showingImportCode = false
    @State private var showingImageImport = false

    enum TrainingHubSection: String, CaseIterable {
        case active = "active"
        case library = "library"

        var displayName: String {
            switch self {
            case .active: return "Plan Activo"
            case .library: return "Mis Planes"
            }
        }

        var icon: String {
            switch self {
            case .active: return "dumbbell.fill"
            case .library: return "folder.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section Picker
            sectionPicker

            // Content based on selection
            Group {
                switch selectedView {
                case .active:
                    if trainingManager.trainingData.isEmpty {
                        activePlanEmptyState
                    } else {
                        ActiveTrainingView()
                            .environmentObject(trainingManager)
                            .environmentObject(authManager)
                    }
                case .library:
                    TrainingPlanLibraryView()
                        .environmentObject(trainingManager)
                        .environmentObject(authManager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: selectedView) { oldValue, newValue in
                if newValue == .active, let userId = authManager.user?.id {
                    Task {
                        await trainingManager.loadActiveTrainingPlan(userId: userId)

                        if trainingManager.trainingPlanId == nil {
                            await MainActor.run {
                                trainingManager.clearAllData()
                            }
                        }
                    }
                }
            }

        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreatePlan) {
            CreateTrainingPlanView()
                .environmentObject(trainingManager)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingPlanEditor) {
            TrainingPlanEditorView(planId: nil, existingPlan: nil)
                .environmentObject(trainingManager)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingImportCode) {
            ImportPlanByCodeView()
                .environmentObject(trainingManager)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingImageImport) {
            CreateTrainingPlanView(initialMethod: .imageUpload)
                .environmentObject(trainingManager)
                .environmentObject(authManager)
        }
    }

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(TrainingHubSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedView = section
                    }
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: section.icon)
                                .font(.system(size: 14, weight: .semibold))

                            Text(section.displayName)
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(
                            selectedView == section ? .blue : .secondary
                        )

                        Rectangle()
                            .fill(
                                selectedView == section
                                    ? Color.blue : Color.clear
                            )
                            .frame(height: 2)
                            .animation(
                                .easeInOut(duration: 0.2),
                                value: selectedView
                            )
                    }
                    .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity)
            }

            if selectedView == .library {
                Menu {
                    Button {
                        showingPlanEditor = true
                    } label: {
                        Label(
                            "Crear Plan Completo",
                            systemImage: "plus.rectangle.on.rectangle"
                        )
                    }

                    Button {
                        showingCreatePlan = true
                    } label: {
                        Label(
                            "Asistente de Creación",
                            systemImage: "wand.and.stars"
                        )
                    }

                    Button {
                        showingImageImport = true
                    } label: {
                        Label(
                            "Importar desde Imagen",
                            systemImage: "photo.on.rectangle"
                        )
                    }

                    Divider()

                    Button {
                        showingImportCode = true
                    } label: {
                        Label(
                            "Importar con Código",
                            systemImage: "key"
                        )
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 4)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 1)
        .padding(.top, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    private var activePlanEmptyState: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .blue.opacity(0.2), .blue.opacity(0.05),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .blue.opacity(0.2), radius: 20, x: 0, y: 10)
            }

            VStack(spacing: 12) {
                Text("No tienes un plan activo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Crea un nuevo plan o activa uno desde tu biblioteca")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            VStack(spacing: 12) {
                Button {
                    showingPlanEditor = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                            .font(.title3)

                        Text("Crear Plan Completo")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    .contentShape(Rectangle())
                }

                Button {
                    showingCreatePlan = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.title3)

                        Text("Asistente de Creación")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                }

                Button {
                    selectedView = .library
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.fill")
                            .font(.title3)

                        Text("Ver Mis Planes")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, -50)
    }
}

// MARK: - Training Plan Library View
struct TrainingPlanLibraryView: View {
    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @State private var trainingPlans: [TrainingPlan] = []
    @State private var isLoading = false
    @State private var showingCreatePlan = false

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Cargando planes...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if trainingPlans.isEmpty {
                libraryEmptyState
            } else {
                plansList.padding(.bottom, 55)
            }
        }
        .onAppear {
            loadTrainingPlans()
        }
        .refreshable {
            loadTrainingPlans()
        }
    }

    private var libraryEmptyState: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .gray.opacity(0.2), .gray.opacity(0.05),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
            }

            VStack(spacing: 12) {
                Text("Biblioteca vacía")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Crea tu primer plan de entrenamiento")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingCreatePlan = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)

                    Text("Crear Plan")
                        .fontWeight(.semibold)
                }
                .frame(width: 200, height: 44)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingCreatePlan) {
            CreateTrainingPlanView()
                .environmentObject(trainingManager)
                .environmentObject(authManager)
        }
    }

    private var plansList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(trainingPlans) { plan in
                    TrainingPlanCard(
                        plan: plan,
                        onActivate: {
                            activatePlan(plan)
                        },
                        onDelete: {
                            deletePlan(plan)
                        }
                    )
                }
            }
            .padding()
        }
    }

    private func loadTrainingPlans() {
        guard let userId = authManager.user?.id else { return }

        isLoading = true

        Task {
            do {
                let plans = try await APIService.shared.listTrainingPlans(
                    userId: userId
                )
                await MainActor.run {
                    self.trainingPlans = plans.map { serverPlan in
                        TrainingPlan(
                            id: serverPlan.id ?? "",
                            name: serverPlan.filename,
                            isActive: serverPlan.active,
                            startDate: serverPlan.planStartDate,
                            endDate: serverPlan.planEndDate,
                            createdAt: serverPlan.createdAt,
                            trainingDays: serverPlan.trainingData?.map { day in
                                // Crear TrainingDay completo con ejercicios
                                let trainingDay = TrainingDay(
                                    day: day.day,
                                    workoutName: day.workoutName
                                )

                                // Añadir ejercicios al día
                                trainingDay.exercises =
                                    day.output?.enumerated().map {
                                        index,
                                        serverExercise in
                                        Exercise(
                                            name: serverExercise.name,
                                            sets: serverExercise.sets,
                                            reps: serverExercise.reps,
                                            restSeconds: serverExercise
                                                .restSeconds,
                                            notes: serverExercise.notes,
                                            tempo: serverExercise.tempo,
                                            weightTracking: serverExercise
                                                .weightTracking,
                                            orderIndex: index
                                        )
                                    } ?? []

                                return trainingDay
                            } ?? []
                        )
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    // Handle error
                }
            }
        }
    }

    private func activatePlan(_ plan: TrainingPlan) {
        guard let userId = authManager.user?.id else { return }

        Task {
            do {
                try await APIService.shared.activateTrainingPlan(
                    userId: userId,
                    planId: plan.id
                )

                // 🔧 AÑADIR: Actualizar el estado local inmediatamente
                await MainActor.run {
                    // Desactivar todos los planes
                    for index in trainingPlans.indices {
                        trainingPlans[index].isActive = false
                    }

                    // Activar el plan seleccionado
                    if let planIndex = trainingPlans.firstIndex(where: {
                        $0.id == plan.id
                    }) {
                        trainingPlans[planIndex].isActive = true
                    }
                }

                // 🔧 AÑADIR: Recargar el plan activo en TrainingManager
                await trainingManager.loadActiveTrainingPlan(userId: userId)

                // Opcional: Recargar toda la lista para estar 100% sincronizado
                // loadTrainingPlans()

            } catch {
                print("Error activating plan: \(error)")
                // Manejar error - podrías mostrar un alert
            }
        }
    }

    private func deletePlan(_ plan: TrainingPlan) {
        guard let userId = authManager.user?.id else { return }
        
        Task {
            do {
                // Eliminar del servidor
                try await APIService.shared.deleteTrainingPlan(
                    userId: userId,
                    planId: plan.id
                )
                
                // Si era el plan activo, limpiar todo localmente
                if plan.isActive {
                    await MainActor.run {
                        trainingManager.clearAllData()
                    }
                }
                
                // Recargar la lista y verificar si hay un plan activo
                loadTrainingPlans()
                
                // Verificar si todavía hay un plan activo después de eliminar
                await trainingManager.loadActiveTrainingPlan(userId: userId)
                
            } catch {
                print("Error deleting plan: \(error)")
            }
        }
    }
}

// MARK: - Training Plan Card
struct TrainingPlanCard: View {
    let plan: TrainingPlan
    let onActivate: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var authManager: AuthManager

    @State private var showingDeleteAlert = false
    @State private var showingEditor = false
    @State private var isActivating = false
    @State private var showingShareCode = false
    @State private var shareCode: String?
    @State private var shareExpiresAt: Date?
    @State private var isSharing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.headline)
                        .fontWeight(.bold)

                    if plan.isActive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Plan Activo")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                }

                Spacer()

                Menu {
                    Button("Editar Plan") {
                        showingEditor = true
                    }

                    Button {
                        sharePlan()
                    } label: {
                        Label(
                            isSharing ? "Compartiendo..." : "Compartir",
                            systemImage: "square.and.arrow.up"
                        )
                    }
                    .disabled(isSharing)

                    if !plan.isActive {
                        Button(isActivating ? "Activando..." : "Activar") {
                            isActivating = true
                            onActivate()
                            // Reset después de un delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2)
                            {
                                isActivating = false
                            }
                        }
                        .disabled(isActivating)
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(isActivating ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    Divider()

                    Button("Eliminar", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }

            // Plan Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(
                        "\(plan.trainingDays.count) días",
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Spacer()

                    if let createdAt = plan.createdAt {
                        Text("Creado \(createdAt, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let startDate = plan.startDate, let endDate = plan.endDate {
                    HStack {
                        Label("Duración", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(
                            "\(startDate, style: .date) - \(endDate, style: .date)"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }

                // Training days preview
                if !plan.trainingDays.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(plan.trainingDays.prefix(5)) { day in
                                Text(day.day)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }

                            if plan.trainingDays.count > 5 {
                                Text("+\(plan.trainingDays.count - 5)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button("Editar") {
                    showingEditor = true
                }
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
                .contentShape(Rectangle())

                if !plan.isActive {
                    Button("Activar") {
                        onActivate()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .alert("Eliminar Plan", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive, action: onDelete)
        } message: {
            Text(
                "¿Estás seguro de que deseas eliminar este plan? Esta acción no se puede deshacer."
            )
        }
        .sheet(isPresented: $showingEditor) {
            TrainingPlanEditorView(
                planId: plan.id,
                existingPlan: plan
            )
        }
        .sheet(isPresented: $showingShareCode) {
            ShareCodeView(code: shareCode ?? "", expiresAt: shareExpiresAt)
        }
    }

    private func sharePlan() {
        guard let userId = authManager.user?.id else { return }
        isSharing = true

        Task {
            do {
                let response = try await APIService.shared.sharePlan(
                    userId: userId,
                    planId: plan.id
                )
                await MainActor.run {
                    shareCode = response.code
                    shareExpiresAt = response.expiresAt
                    isSharing = false
                    showingShareCode = true
                }
            } catch {
                await MainActor.run {
                    isSharing = false
                }
                print("Error sharing plan: \(error)")
            }
        }
    }
}

// MARK: - Supporting Models
struct TrainingPlan: Identifiable {
    let id: String
    let name: String
    var isActive: Bool  // 🔧 CAMBIAR: De 'let' a 'var' para poder modificarlo
    let startDate: Date?
    let endDate: Date?
    let createdAt: Date?
    let trainingDays: [TrainingDay]
}

// MARK: - Active Training View (Your existing TrainingView)
struct ActiveTrainingView: View {
    var body: some View {
        TrainingView()
    }
}

// MARK: - Share Code View
struct ShareCodeView: View {
    let code: String
    let expiresAt: Date?
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .blue.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                    }

                    Text("Plan Compartido")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Comparte este código con otro usuario para que pueda importar tu plan")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Code display
                VStack(spacing: 12) {
                    Text(code)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .tracking(8)
                        .foregroundColor(.blue)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                        )

                    Button {
                        UIPasteboard.general.string = code
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copiado" : "Copiar Código")
                                .fontWeight(.semibold)
                        }
                        .frame(width: 200, height: 44)
                        .background(copied ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    if let expiresAt = expiresAt {
                        Text("Expira \(expiresAt, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Import Plan By Code View
struct ImportPlanByCodeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var trainingManager: TrainingManager
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var importSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .blue.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "key")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                    }

                    Text("Importar Plan")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Ingresa el código de 6 caracteres que te compartieron")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 16) {
                    TextField("CÓDIGO", text: $code)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .tracking(6)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        .onChange(of: code) { _, newValue in
                            // Limit to 6 characters and force uppercase
                            let filtered = String(newValue.uppercased().prefix(6))
                            if filtered != newValue {
                                code = filtered
                            }
                            errorMessage = nil
                        }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    if importSuccess {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Plan importado exitosamente")
                        }
                        .font(.subheadline)
                        .foregroundColor(.green)
                    }

                    Button {
                        importPlan()
                    } label: {
                        HStack(spacing: 8) {
                            if isImporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.down.circle")
                            }
                            Text(isImporting ? "Importando..." : "Importar Plan")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(code.count == 6 && !isImporting ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(code.count != 6 || isImporting)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func importPlan() {
        guard let userId = authManager.user?.id else { return }
        guard code.count == 6 else { return }

        isImporting = true
        errorMessage = nil

        Task {
            do {
                _ = try await APIService.shared.importSharedPlan(
                    userId: userId,
                    code: code
                )
                await MainActor.run {
                    isImporting = false
                    importSuccess = true
                }
                // Dismiss after a short delay
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = "Código inválido o expirado"
                }
            }
        }
    }
}
