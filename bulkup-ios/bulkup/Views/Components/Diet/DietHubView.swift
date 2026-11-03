//
//  DietHubView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 10/2/26.
//

import SwiftUI

struct DietHubView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dietManager: DietManager
    @ObservedObject private var storeKit = StoreKitManager.shared
    /// Free tier keeps one active diet plan; creating another asks for PRO.
    private var canCreateAnotherPlan: Bool {
        storeKit.isSubscribed || dietManager.dietPlanId == nil
    }
    @State private var selectedView: DietHubSection = .active
    @State private var showingCreateDietPlan = false
    @State private var showingDietPlanEditor = false
    @State private var showingSubscription = false
    @State private var showingFoodPreferences = false

    enum DietHubSection: String, CaseIterable {
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
            case .active: return "leaf.fill"
            case .library: return "folder.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker

            Group {
                switch selectedView {
                case .active:
                    if dietManager.isLoading { loadingView }
                    else if dietManager.dietData.isEmpty { activePlanEmptyState }
                    else { activePlanContent }
                case .library:
                    DietPlanLibraryView()
                        .environmentObject(dietManager)
                        .environmentObject(authManager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BulkUpGround())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingCreateDietPlan) {
            CreateDietPlanView()
                .environmentObject(dietManager)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingDietPlanEditor) {
            DietPlanEditorView()
                .environmentObject(dietManager)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingFoodPreferences) {
            FoodPreferencesView()
        }
        .onAppear {
            if dietManager.dietData.isEmpty && !dietManager.isLoading {
                if let userId = authManager.user?.id {
                    Task {
                        await dietManager.loadActiveDietPlan(userId: userId)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDietLibrary)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) { selectedView = .library }
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: Spacing.sm) {
            HStack(spacing: 0) {
                ForEach(DietHubSection.allCases, id: \.self) { section in
                    let isActive = selectedView == section
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedView = section }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: section.icon)
                                .font(.system(.footnote, weight: .semibold))
                            Text(section.displayName)
                                .font(.system(.subheadline, weight: .bold))
                        }
                        .foregroundColor(isActive ? BulkUpColors.accentText : BulkUpColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 40)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                .fill(isActive ? BulkUpColors.accent.opacity(0.16) : Color.clear)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(BulkUpColors.surface)
            )
            .lift(CornerRadius.medium)

            Menu {
                if selectedView == .active {
                    Button { showingFoodPreferences = true } label: {
                        Label("Preferencias y alergias", systemImage: "fork.knife.circle")
                    }
                    Divider()
                }
                Button {
                    if storeKit.isSubscribed { showingCreateDietPlan = true } else { showingSubscription = true }
                } label: { Label("Importar con IA", systemImage: "sparkles") }
                Button { if canCreateAnotherPlan { showingDietPlanEditor = true } else { showingSubscription = true } } label: {
                    Label("Crear manualmente", systemImage: "square.and.pencil")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(BulkUpColors.textPrimary)
                    .frame(width: 46, height: 46)
                    .background(BulkUpColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    .lift(CornerRadius.medium)
            }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.sm)
        .padding(.top, Spacing.md)
    }

    // MARK: - Plan Header

    private var planHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(dietManager.activePlanName ?? NSLocalizedString("Plan de Dieta", comment: ""))
                .titleVoice(.largeTitle)
                .foregroundColor(BulkUpColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            if dietManager.dietData.count > 1 {
                Text("\(dietManager.dietData.count) días · \(totalMealCount) comidas")
                    .font(BulkUpFont.numeric(.subheadline, weight: .medium))
                    .foregroundColor(BulkUpColors.textSecondary)
            } else {
                Text("\(totalMealCount) comidas al día")
                    .font(BulkUpFont.numeric(.subheadline, weight: .medium))
                    .foregroundColor(BulkUpColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
    }

    private var totalMealCount: Int {
        dietManager.dietData.first?.meals.count ?? 0
    }

    // MARK: - Active Plan Content

    private var activePlanContent: some View {
        VStack(spacing: 0) {
            planHeader

            DietFidelityView()
                .padding(.horizontal, Spacing.screenH)
                .padding(.bottom, Spacing.lg)

            DietView()
                .environmentObject(dietManager)
                .environmentObject(authManager)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.xl) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(BulkUpColors.diet)

            VStack(spacing: Spacing.sm) {
                Text("Cargando tu plan...")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("Preparando tu alimentacion perfecta")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var activePlanEmptyState: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.lg) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                            .fill(BulkUpColors.surface)
                            .frame(width: 88, height: 88)
                            .lift(CornerRadius.xl)

                        Image(systemName: "leaf.fill")
                            .font(.system(.largeTitle, weight: .semibold))
                            .foregroundColor(BulkUpColors.accentText)
                    }
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
                    // Importar con IA
                    Button {
                        if storeKit.isSubscribed {
                            showingCreateDietPlan = true
                        } else {
                            showingSubscription = true
                        }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                                    .fill(BulkUpColors.surfaceElevated)
                                    .frame(width: 44, height: 44)

                                Image(systemName: "sparkles")
                                    .font(.system(.title3, weight: .medium))
                                    .foregroundColor(BulkUpColors.accentText)
                            }

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                HStack(spacing: 6) {
                                    Text("Importar con IA")
                                        .font(BulkUpFont.cardTitle())
                                        .foregroundColor(BulkUpColors.textPrimary)

                                    if !storeKit.isSubscribed {
                                        Text("PRO")
                                            .font(.system(.caption2, weight: .bold))
                                            .foregroundColor(BulkUpColors.onAccent)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(BulkUpColors.accent)
                                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                    }
                                }

                                Text("Sube un PDF o foto de tu dieta")
                                    .font(BulkUpFont.body())
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: storeKit.isSubscribed ? "chevron.right" : "lock.fill")
                                .font(.system(.footnote, weight: .semibold))
                                .foregroundColor(BulkUpColors.textTertiary)
                        }
                        .padding(Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                                .fill(BulkUpColors.surface)
                        )
                        .lift(stroke: BulkUpColors.accent.opacity(0.5))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Crear manualmente
                    Button {
                        if canCreateAnotherPlan { showingDietPlanEditor = true } else { showingSubscription = true }
                    } label: {
                        dietCreationOptionRow(
                            icon: "square.and.pencil",
                            title: "Crear manualmente",
                            subtitle: "Construye tu plan paso a paso"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)

                // Ver Mis Planes link
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedView = .library }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "folder.fill")
                            .font(BulkUpFont.body())

                        Text("Ver mis planes")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(BulkUpColors.accentText)
                }
                .padding(.top, Spacing.xs)
            }
            .padding(.top, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BulkUpColors.background)
    }

    private func dietCreationOptionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(BulkUpColors.surfaceElevated)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(.title3, weight: .medium))
                    .foregroundColor(BulkUpColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(title))
                    .font(BulkUpFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(BulkUpColors.textPrimary)

                Text(LocalizedStringKey(subtitle))
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(BulkUpColors.textTertiary)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                .fill(BulkUpColors.surface)
        )
        .lift()
        .contentShape(Rectangle())
    }
}

// MARK: - Diet Plan Library View
struct DietPlanLibraryView: View {
    @EnvironmentObject var dietManager: DietManager
    @EnvironmentObject var authManager: AuthManager
    @State private var dietPlans: [DietPlan] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: Spacing.lg) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Cargando planes...")
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if dietPlans.isEmpty {
                libraryEmptyState
            } else {
                plansList
            }
        }
        .onAppear {
            loadDietPlans()
        }
        .refreshable {
            loadDietPlans()
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
                                    BulkUpColors.textTertiary.opacity(0.2), BulkUpColors.textTertiary.opacity(0.05),
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
                Text("Biblioteca vacia")
                    .font(BulkUpFont.sectionHeader())
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("Sube tu primer plan de dieta")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var plansList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(dietPlans) { plan in
                    DietPlanCard(
                        plan: plan,
                        onActivate: {
                            activatePlan(plan)
                        },
                        onDelete: {
                            deletePlan(plan)
                        },
                        onUpdated: {
                            loadDietPlans()
                        }
                    )
                }
            }
            .padding()
        }
    }

    private func loadDietPlans() {
        guard let userId = authManager.user?.id else { return }

        isLoading = true

        Task {
            do {
                let plans = try await APIService.shared.listDietPlans(userId: userId)
                await MainActor.run {
                    self.dietPlans = plans.map { serverPlan in
                        DietPlan(
                            id: serverPlan.id ?? "",
                            name: serverPlan.filename,
                            isActive: serverPlan.active,
                            createdAt: serverPlan.createdAt,
                            dietDays: serverPlan.dietData?.map { day in
                                DietDaySummary(
                                    day: day.day,
                                    mealCount: day.meals.count,
                                    supplementCount: day.supplements?.count ?? 0
                                )
                            } ?? [],
                            serverDietData: serverPlan.dietData ?? []
                        )
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    private func activatePlan(_ plan: DietPlan) {
        guard let userId = authManager.user?.id else { return }

        Task {
            do {
                try await APIService.shared.activateDietPlan(
                    userId: userId,
                    planId: plan.id
                )

                await MainActor.run {
                    for index in dietPlans.indices {
                        dietPlans[index].isActive = false
                    }
                    if let planIndex = dietPlans.firstIndex(where: { $0.id == plan.id }) {
                        dietPlans[planIndex].isActive = true
                    }
                }

                await dietManager.loadActiveDietPlan(userId: userId)

            } catch {
                print("Error activating diet plan: \(error)")
            }
        }
    }

    private func deletePlan(_ plan: DietPlan) {
        guard let userId = authManager.user?.id else { return }

        Task {
            do {
                try await APIService.shared.deleteDietPlan(
                    userId: userId,
                    planId: plan.id
                )

                if plan.isActive {
                    await MainActor.run {
                        dietManager.clearAllData()
                    }
                }

                loadDietPlans()
                await dietManager.loadActiveDietPlan(userId: userId)

            } catch {
                print("Error deleting diet plan: \(error)")
            }
        }
    }
}

// MARK: - Diet Plan Card
struct DietPlanCard: View {
    let plan: DietPlan
    let onActivate: () -> Void
    let onDelete: () -> Void
    var onUpdated: () -> Void = {}

    @State private var showingDeleteAlert = false
    @State private var showingEditor = false
    @State private var isActivating = false

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
                                .fill(BulkUpColors.complete)
                                .frame(width: 8, height: 8)
                            Text("Plan activo")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.complete)
                                .fontWeight(.medium)
                        }
                    }
                }

                Spacer()

                Menu {
                    if !plan.isActive {
                        Button(isActivating ? "Activando..." : "Activar") {
                            isActivating = true
                            onActivate()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isActivating = false
                            }
                        }
                        .disabled(isActivating)
                    }

                    Button("Editar") {
                        showingEditor = true
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
                        "\(plan.dietDays.count) días",
                        systemImage: "calendar"
                    )
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

                    Spacer()

                    Text("Creado \(plan.createdAt, style: .relative)")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                if let totalMeals = plan.dietDays.first?.mealCount {
                    Label(
                        "\(totalMeals) comidas por dia",
                        systemImage: "fork.knife"
                    )
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                }

                // Day name chips preview
                if !plan.dietDays.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(plan.dietDays.prefix(5), id: \.day) { day in
                                Text(WeekdayLabel.localized(day.day))
                                    .font(BulkUpFont.caption())
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xs)
                                    .background(BulkUpColors.diet.opacity(0.1))
                                    .foregroundColor(BulkUpColors.diet)
                                    .cornerRadius(CornerRadius.small)
                            }

                            if plan.dietDays.count > 5 {
                                Text("+\(plan.dietDays.count - 5)")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }
                        }
                    }
                }
            }

            // Action Buttons
            if !plan.isActive {
                Button("Activar") {
                    onActivate()
                }
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(BulkUpColors.diet)
                .foregroundColor(Color.onFill(BulkUpColors.diet))
                .cornerRadius(CornerRadius.small)
                .contentShape(Rectangle())
            }
        }
        .cardStyle()
        .alert("Eliminar Plan", isPresented: $showingDeleteAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive, action: onDelete)
        } message: {
            Text(
                "Estas seguro de que deseas eliminar este plan? Esta accion no se puede deshacer."
            )
        }
        .sheet(isPresented: $showingEditor, onDismiss: onUpdated) {
            DietPlanEditorView(planId: plan.id, existingPlan: plan)
        }
    }
}

// MARK: - Supporting Models
struct DietPlan: Identifiable {
    let id: String
    let name: String
    var isActive: Bool
    let createdAt: Date
    let dietDays: [DietDaySummary]
    // Full server data, kept so the editor can prefill the whole plan.
    let serverDietData: [ServerDietDay]
}

struct DietDaySummary {
    let day: String
    let mealCount: Int
    let supplementCount: Int
}
