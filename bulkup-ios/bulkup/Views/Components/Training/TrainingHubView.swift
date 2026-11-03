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
    @ObservedObject private var storeKit = StoreKitManager.shared
    @ObservedObject private var workoutSession = WorkoutSessionManager.shared
    @State private var selectedView: TrainingHubSection = .active
    @AppStorage("trainingViewMode") private var trainingViewMode: TrainingView.ViewMode = .day
    @State private var showingPlanEditor = false
    @State private var showingImportCode = false
    @State private var showingImport = false
    @State private var showingTemplateWizard = false
    @State private var showingSubscription = false
    @State private var showingExerciseLibrary = false
    @State private var showingActions = false
    /// Chosen in the actions sheet; presented once that sheet has dismissed.
    @State private var pendingAction: PlanAction?

    /// Free tier keeps one active plan; a second one (template, manual, import)
    /// asks for PRO. "Planes ilimitados" on the paywall is this gate.
    private var canCreateAnotherPlan: Bool {
        storeKit.isSubscribed || trainingManager.trainingPlanId == nil
    }

    enum TrainingHubSection: String, CaseIterable {
        case active = "active"
        case library = "library"

        var displayName: LocalizedStringKey {
            switch self {
            case .active: return "Plan activo"
            case .library: return "Mis planes"
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
            // Section Picker — hidden during an active workout to remove
            // distractions (focus mode).
            if !workoutSession.isActive {
                sectionPicker
            }

            // Content based on selection
            Group {
                switch selectedView {
                case .active:
                    if trainingManager.trainingData.isEmpty {
                        EmptyHubView(
                            kind: .training,
                            isSubscribed: storeKit.isSubscribed,
                            canCreateAnother: canCreateAnotherPlan,
                            onAction: { perform($0) },
                            onShowLibrary: { withAnimation(.easeInOut(duration: 0.2)) { selectedView = .library } }
                        )
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
        .sheet(isPresented: $showingTemplateWizard) {
            CreateTrainingPlanView(initialMethod: .template)
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
        .sheet(isPresented: $showingImport) {
            ImportPlanView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingActions, onDismiss: runPendingAction) {
            PlanActionsSheet(
                kind: .training,
                isSubscribed: storeKit.isSubscribed,
                canCreateAnother: canCreateAnotherPlan,
                hasActivePlan: selectedView == .active && !trainingManager.trainingData.isEmpty,
                viewMode: $trainingViewMode,
                onAction: { pendingAction = $0 }
            )
        }
        .sheet(isPresented: $showingExerciseLibrary) {
            ExerciseExplorerView()
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
                .environmentObject(authManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTrainingLibrary)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedView = .library
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTraining)) { _ in
            // An imported routine lands on the plan, not the library.
            withAnimation(.easeInOut(duration: 0.2)) { selectedView = .active }
        }
    }

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            // Segmented control pill
            HStack(spacing: 0) {
                ForEach(TrainingHubSection.allCases, id: \.self) { section in
                    let isActive = selectedView == section
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedView = section
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: section.icon)
                                .font(.system(.footnote, weight: .semibold))

                            Text(section.displayName)
                                .font(.system(.subheadline, weight: .bold))
                        }
                        .foregroundColor(
                            isActive ? BulkUpColors.accentText : BulkUpColors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 40)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                .fill(isActive ? BulkUpColors.accent.opacity(0.16) : Color.clear)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                    }
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(BulkUpColors.surface)
            )
            .lift(CornerRadius.medium)

            Button {
                showingActions = true
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(BulkUpColors.textPrimary)
                    .frame(width: 46, height: 46)
                    .background(BulkUpColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    .lift(CornerRadius.medium)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Más opciones")
            .padding(.leading, Spacing.sm)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.sm)
        .padding(.top, Spacing.md)
        .background(BulkUpColors.background)
    }

    // MARK: - Actions (from the sheet and the empty hub)

    private func perform(_ action: PlanAction) {
        switch action {
        case .importFile:
            if storeKit.isSubscribed { showingImport = true } else { showingSubscription = true }
        case .template:
            if canCreateAnotherPlan { showingTemplateWizard = true } else { showingSubscription = true }
        case .manual:
            if canCreateAnotherPlan { showingPlanEditor = true } else { showingSubscription = true }
        case .code:
            if storeKit.isSubscribed { showingImportCode = true } else { showingSubscription = true }
        case .exerciseLibrary:
            showingExerciseLibrary = true
        case .foodPreferences:
            break
        }
    }

    /// A sheet cannot present another while it is still dismissing.
    private func runPendingAction() {
        guard let action = pendingAction else { return }
        pendingAction = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { perform(action) }
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
                VStack(spacing: Spacing.lg) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(BulkUpColors.training)
                    Text("Cargando planes...")
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if trainingPlans.isEmpty {
                libraryEmptyState
            } else {
                plansList
            }
        }
        .background(BulkUpColors.background)
        .onAppear {
            loadTrainingPlans()
        }
        .refreshable {
            loadTrainingPlans()
        }
    }

    private var libraryEmptyState: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(BulkUpColors.surfaceElevated)
                        .frame(width: 80, height: 80)

                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }

            VStack(spacing: Spacing.md) {
                Text("Biblioteca vacía")
                    .font(BulkUpFont.sectionHeader())
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("Crea tu primer plan de entrenamiento")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingCreatePlan = true
            } label: {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "plus.circle.fill")
                        .font(BulkUpFont.sectionHeader())

                    Text("Crear Plan")
                        .fontWeight(.semibold)
                }
                .primaryButtonStyle(color: BulkUpColors.training)
            }
            .frame(width: 200)
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
            LazyVStack(spacing: Spacing.md) {
                ForEach(trainingPlans) { plan in
                    TrainingPlanCard(
                        plan: plan,
                        onActivate: {
                            activatePlan(plan)
                        },
                        onDelete: {
                            deletePlan(plan)
                        },
                        onUpdated: {
                            loadTrainingPlans()
                        }
                    )
                }
            }
            .padding(Spacing.lg)
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

                await trainingManager.loadActiveTrainingPlan(userId: userId)

            } catch {
                print("Error activating plan: \(error)")
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
    var onUpdated: () -> Void = {}
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var storeKit = StoreKitManager.shared
    @ObservedObject private var workoutSession = WorkoutSessionManager.shared

    @State private var showingDeleteAlert = false
    @State private var showingEditor = false
    @State private var isActivating = false
    @State private var showingShareCode = false
    @State private var showingSubscription = false
    @State private var shareCode: String?
    @State private var shareExpiresAt: Date?
    @State private var isSharing = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(plan.name)
                        .font(BulkUpFont.cardTitle())
                        .fontWeight(.bold)
                        .foregroundColor(BulkUpColors.textPrimary)

                    if plan.isActive {
                        HStack(spacing: Spacing.xs) {
                            Circle()
                                .fill(BulkUpColors.success)
                                .frame(width: 8, height: 8)
                            Text("Plan Activo")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.success)
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
                        if storeKit.isSubscribed {
                            sharePlan()
                        } else {
                            showingSubscription = true
                        }
                    } label: {
                        Label(
                            storeKit.isSubscribed
                                ? (isSharing ? "Compartiendo..." : "Compartir")
                                : "Compartir (PRO)",
                            systemImage: storeKit.isSubscribed ? "square.and.arrow.up" : "lock.fill"
                        )
                    }
                    .disabled(isSharing)

                    if !plan.isActive {
                        Button(isActivating ? "Activando..." : "Activar") {
                            isActivating = true
                            onActivate()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2)
                            {
                                isActivating = false
                            }
                        }
                        .disabled(isActivating)
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(isActivating ? BulkUpColors.textTertiary : BulkUpColors.success)
                        .foregroundColor(Color.onFill(isActivating ? BulkUpColors.textTertiary : BulkUpColors.success))
                        .cornerRadius(CornerRadius.small)
                    }

                    Divider()

                    Button("Eliminar", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }

            // Plan Info
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Label(
                        "\(plan.trainingDays.count) días",
                        systemImage: "calendar"
                    )
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

                    Spacer()

                    if let createdAt = plan.createdAt {
                        Text("Creado \(createdAt, style: .relative)")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                }

                if let startDate = plan.startDate, let endDate = plan.endDate {
                    HStack {
                        Label("Duración", systemImage: "clock")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)

                        Text(
                            "\(startDate, style: .date) - \(endDate, style: .date)"
                        )
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                    }
                }

                // Training days preview
                if !plan.trainingDays.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(plan.trainingDays.prefix(5)) { day in
                                Text(WeekdayLabel.localized(day.day))
                                    .font(BulkUpFont.caption())
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .background(BulkUpColors.training.opacity(0.1))
                                    .foregroundColor(BulkUpColors.training)
                                    .cornerRadius(CornerRadius.small / 2)
                            }

                            if plan.trainingDays.count > 5 {
                                Text("+\(plan.trainingDays.count - 5)")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }
                        }
                    }
                }
            }

            // Action Buttons
            HStack(spacing: Spacing.md) {
                Button("Editar") {
                    showingEditor = true
                }
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(BulkUpColors.training.opacity(0.1))
                .foregroundColor(BulkUpColors.training)
                .cornerRadius(CornerRadius.small)
                .contentShape(Rectangle())

                if !plan.isActive {
                    Button("Activar") {
                        onActivate()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(BulkUpColors.success)
                    .foregroundColor(Color.onFill(BulkUpColors.success))
                    .cornerRadius(CornerRadius.small)
                    .contentShape(Rectangle())
                }
            }
        }
        .cardStyle()
        .alert("Eliminar Plan", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive, action: onDelete)
        } message: {
            Text(
                "¿Estás seguro de que deseas eliminar este plan? Esta acción no se puede deshacer."
            )
        }
        .sheet(isPresented: $showingEditor, onDismiss: onUpdated) {
            TrainingPlanEditorView(
                planId: plan.id,
                existingPlan: plan
            )
        }
        .sheet(isPresented: $showingShareCode) {
            ShareCodeView(code: shareCode ?? "", expiresAt: shareExpiresAt)
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
                .environmentObject(authManager)
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
    var isActive: Bool
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
            VStack(spacing: Spacing.xxl) {
                Spacer()

                VStack(spacing: Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(BulkUpColors.surfaceElevated)
                            .frame(width: 80, height: 80)

                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 36))
                            .foregroundColor(BulkUpColors.training)
                    }

                    Text("Plan Compartido")
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.textPrimary)

                    Text("Comparte este código con otro usuario para que pueda importar tu plan")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                // Code display
                VStack(spacing: Spacing.md) {
                    Text(code)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .tracking(8)
                        .foregroundColor(BulkUpColors.training)
                        .padding(.vertical, 20)
                        .padding(.horizontal, Spacing.xxl)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.large)
                                .fill(BulkUpColors.training.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: CornerRadius.large)
                                        .strokeBorder(BulkUpColors.training.opacity(0.2), lineWidth: 1)
                                )
                        )

                    Button {
                        UIPasteboard.general.string = code
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copiado" : "Copiar Código")
                                .fontWeight(.semibold)
                        }
                        .frame(width: 200, height: 44)
                        .background(copied ? BulkUpColors.success : BulkUpColors.training)
                        .foregroundColor(Color.onFill(copied ? BulkUpColors.success : BulkUpColors.training))
                        .cornerRadius(CornerRadius.medium)
                    }

                    if let expiresAt = expiresAt {
                        Text("Expira \(expiresAt, style: .relative)")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(BulkUpColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        dismiss()
                    }
                    .foregroundColor(BulkUpColors.training)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Import Plan By Code View
/// Six characters someone shared; the plan lands in the library.
struct ImportPlanByCodeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var trainingManager: TrainingManager
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var importSuccess = false
    @FocusState private var codeFocused: Bool
    @State private var contentHeight: CGFloat = 0

    private var canImport: Bool { code.count == 6 && !isImporting && !importSuccess }

    var body: some View {
        ZStack {
            BulkUpGround()

            ScrollView(showsIndicators: false) {
              VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Tengo un código")
                        .titleVoice(.title)
                        .foregroundColor(BulkUpColors.textPrimary)
                    Spacer(minLength: Spacing.md)
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

                Text("Seis letras o números, los que te ha pasado quien compartió el plan.")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)

                TextField("ABC123", text: $code)
                    .font(BulkUpFont.mono(32, weight: .semibold, relativeTo: .largeTitle))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .tracking(6)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($codeFocused)
                    .tint(BulkUpColors.accentText)
                    .frame(minHeight: 64)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .strokeBorder(BulkUpColors.accent, lineWidth: codeFocused ? 1.5 : 0)
                    )
                    .accessibilityLabel("Código del plan")
                    .onChange(of: code) { _, newValue in
                        let filtered = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
                        if filtered != newValue { code = filtered }
                        errorMessage = nil
                    }

                if let errorMessage {
                    Text(errorMessage)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.warning)
                }

                if importSuccess {
                    HStack(spacing: Spacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(BulkUpColors.complete)
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(.caption2, weight: .bold))
                                .foregroundColor(Color.onFill(BulkUpColors.complete))
                        }
                        Text("Plan importado. Lo tienes en Mis planes.")
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.textPrimary)
                    }
                    .transition(.opacity)
                }

                Button {
                    importPlan()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if isImporting {
                            ProgressView().tint(BulkUpColors.onAccent)
                        }
                        Text(isImporting ? "Importando…" : "Importar")
                            .font(.system(.headline, weight: .semibold))
                    }
                    .foregroundColor(BulkUpColors.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(BulkUpColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                }
                .buttonStyle(.plain)
                .pressable()
                .disabled(!canImport)
                .opacity(canImport ? 1 : 0.5)
              }
              .padding(.horizontal, Spacing.screenH)
              .padding(.top, Spacing.lg)
              .padding(.bottom, Spacing.sm)
              .measureHeight($contentHeight)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents(contentHeight > 0 ? [.height(contentHeight), .large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(BulkUpColors.background)
        .onAppear { codeFocused = true }
    }

    private func importPlan() {
        guard let userId = authManager.user?.id, code.count == 6 else { return }
        isImporting = true
        errorMessage = nil
        codeFocused = false

        Task {
            do {
                _ = try await APIService.shared.importSharedPlan(userId: userId, code: code)
                await MainActor.run {
                    isImporting = false
                    withAnimation(.easeOut(duration: 0.2)) { importSuccess = true }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                await MainActor.run {
                    dismiss()
                    NotificationCenter.default.post(name: .navigateToTrainingLibrary, object: nil)
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = NSLocalizedString("Código inválido o expirado", comment: "")
                }
            }
        }
    }
}
