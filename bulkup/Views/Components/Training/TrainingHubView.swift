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
    @State private var selectedView: TrainingHubSection = .active
    @State private var showingPlanEditor = false
    @State private var showingImportCode = false
    @State private var showingImageImport = false
    @State private var showingTemplateWizard = false
    @State private var showingSubscription = false

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
        .sheet(isPresented: $showingImageImport) {
            CreateTrainingPlanView(initialMethod: .imageUpload)
                .environmentObject(trainingManager)
                .environmentObject(authManager)
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
                                .font(.system(size: 13, weight: .semibold))

                            Text(section.displayName)
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(
                            isActive ? BulkUpColors.onAccent : BulkUpColors.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            isActive
                                ? Capsule().fill(BulkUpColors.accent)
                                : Capsule().fill(Color.clear)
                        )
                        .contentShape(Capsule())
                    }
                }
            }
            .padding(3)
            .background(
                Capsule().fill(BulkUpColors.surface)
            )

            if selectedView == .library {
                Menu {
                    Button {
                        showingTemplateWizard = true
                    } label: {
                        Label(
                            "Usar plantilla",
                            systemImage: "doc.on.doc"
                        )
                    }

                    Button {
                        showingPlanEditor = true
                    } label: {
                        Label(
                            "Crear manualmente",
                            systemImage: "square.and.pencil"
                        )
                    }

                    Button {
                        if storeKit.isSubscribed {
                            showingImageImport = true
                        } else {
                            showingSubscription = true
                        }
                    } label: {
                        Label(
                            "Importar con IA",
                            systemImage: "sparkles"
                        )
                    }

                    Divider()

                    Button {
                        if storeKit.isSubscribed {
                            showingImportCode = true
                        } else {
                            showingSubscription = true
                        }
                    } label: {
                        Label(
                            "Importar con codigo",
                            systemImage: "qrcode"
                        )
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(BulkUpColors.accent)
                }
                .padding(.trailing, 4)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.sm)
        .padding(.top, Spacing.md)
        .background(BulkUpColors.background)
    }

    private var activePlanEmptyState: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        BulkUpColors.training.opacity(0.2), BulkUpColors.training.opacity(0.05),
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
                                    colors: [BulkUpColors.training, BulkUpColors.training.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(color: BulkUpColors.training.opacity(0.2), radius: 20, x: 0, y: 10)
                }

                VStack(spacing: Spacing.md) {
                    Text("No tienes un plan activo")
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.textPrimary)

                    Text("Crea un nuevo plan o activa uno desde tu biblioteca")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.screenH)
                }

                // Creation options cards
                VStack(spacing: Spacing.md) {
                    // Importar con IA — prominent card (Premium)
                    Button {
                        if storeKit.isSubscribed {
                            showingImageImport = true
                        } else {
                            showingSubscription = true
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [BulkUpColors.training.opacity(0.2), BulkUpColors.training.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(BulkUpColors.training)
                            }

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                HStack(spacing: 6) {
                                    Text("Importar con IA")
                                        .font(BulkUpFont.cardTitle())
                                        .foregroundColor(BulkUpColors.textPrimary)

                                    if !storeKit.isSubscribed {
                                        Text("PRO")
                                            .font(BulkUpFont.caption())
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.purple)
                                            .cornerRadius(4)
                                    }
                                }

                                Text("Sube una foto o PDF de tu rutina")
                                    .font(BulkUpFont.body())
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: storeKit.isSubscribed ? "chevron.right" : "lock.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(storeKit.isSubscribed ? BulkUpColors.training.opacity(0.5) : .purple.opacity(0.6))
                        }
                        .padding(Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .fill(BulkUpColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .stroke(BulkUpColors.training.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: BulkUpColors.training.opacity(0.15), radius: 8, x: 0, y: 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Usar plantilla
                    Button {
                        showingTemplateWizard = true
                    } label: {
                        creationOptionRow(
                            icon: "doc.on.doc",
                            title: "Usar plantilla",
                            subtitle: "Comienza con una plantilla predefinida"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Crear manualmente
                    Button {
                        showingPlanEditor = true
                    } label: {
                        creationOptionRow(
                            icon: "square.and.pencil",
                            title: "Crear manualmente",
                            subtitle: "Construye tu plan paso a paso"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Importar con codigo (Premium)
                    Button {
                        if storeKit.isSubscribed {
                            showingImportCode = true
                        } else {
                            showingSubscription = true
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(BulkUpColors.surfaceElevated)
                                    .frame(width: 44, height: 44)

                                Image(systemName: "qrcode")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(BulkUpColors.training)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("Importar con codigo")
                                        .font(BulkUpFont.body())
                                        .fontWeight(.semibold)
                                        .foregroundColor(BulkUpColors.textPrimary)

                                    if !storeKit.isSubscribed {
                                        Text("PRO")
                                            .font(BulkUpFont.caption())
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.purple)
                                            .cornerRadius(4)
                                    }
                                }

                                Text("Usa un codigo compartido por otro usuario")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: storeKit.isSubscribed ? "chevron.right" : "lock.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(storeKit.isSubscribed ? BulkUpColors.textTertiary : .purple.opacity(0.6))
                        }
                        .padding(Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.medium)
                                .fill(BulkUpColors.surface)
                        )
                        .overlay(RoundedRectangle(cornerRadius: CornerRadius.medium).stroke(BulkUpColors.border, lineWidth: 0.5))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)

                // Ver Mis Planes link
                Button {
                    selectedView = .library
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "folder.fill")
                            .font(BulkUpFont.body())

                        Text("Ver Mis Planes")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(BulkUpColors.training)
                }
                .padding(.top, Spacing.xs)
            }
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BulkUpColors.background)
    }

    private func creationOptionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(BulkUpColors.surfaceElevated)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(BulkUpColors.training)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(BulkUpFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(BulkUpColors.textPrimary)

                Text(subtitle)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(BulkUpColors.textTertiary)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(BulkUpColors.surface)
        )
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.medium).stroke(BulkUpColors.border, lineWidth: 0.5))
        .contentShape(Rectangle())
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
                        .fill(
                            LinearGradient(
                                colors: [
                                    BulkUpColors.textTertiary.opacity(0.3), BulkUpColors.textTertiary.opacity(0.1),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var storeKit = StoreKitManager.shared

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
                        .foregroundColor(.white)
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
                                Text(day.day)
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
                    .foregroundColor(.white)
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
        .sheet(isPresented: $showingEditor) {
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
                            .fill(
                                LinearGradient(
                                    colors: [BulkUpColors.training.opacity(0.2), BulkUpColors.training.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
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
                        .foregroundColor(.white)
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
            VStack(spacing: Spacing.xxl) {
                Spacer()

                VStack(spacing: Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [BulkUpColors.training.opacity(0.2), BulkUpColors.training.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "key")
                            .font(.system(size: 36))
                            .foregroundColor(BulkUpColors.training)
                    }

                    Text("Importar Plan")
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.textPrimary)

                    Text("Ingresa el código de 6 caracteres que te compartieron")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                VStack(spacing: Spacing.lg) {
                    TextField("CÓDIGO", text: $code)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .tracking(6)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(.vertical, Spacing.lg)
                        .padding(.horizontal, Spacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.large)
                                .fill(BulkUpColors.surfaceElevated)
                        )
                        .foregroundColor(BulkUpColors.textPrimary)
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
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.error)
                    }

                    if importSuccess {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Plan importado exitosamente")
                        }
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.success)
                    }

                    Button {
                        importPlan()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            if isImporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.down.circle")
                            }
                            Text(isImporting ? "Importando..." : "Importar Plan")
                                .fontWeight(.semibold)
                        }
                        .primaryButtonStyle(color: code.count == 6 && !isImporting ? BulkUpColors.training : BulkUpColors.textTertiary)
                    }
                    .disabled(code.count != 6 || isImporting)
                }
                .padding(.horizontal, Spacing.xl)

                Spacer()
            }
            .padding()
            .background(BulkUpColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(BulkUpColors.training)
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
                    errorMessage = String(localized: "Código inválido o expirado")
                }
            }
        }
    }
}
