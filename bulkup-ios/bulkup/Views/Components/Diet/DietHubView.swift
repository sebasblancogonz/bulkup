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
    @State private var showingImport = false
    @State private var showingDietPlanEditor = false
    @State private var showingSubscription = false
    @State private var showingFoodPreferences = false
    @State private var showingActions = false
    /// Chosen in the actions sheet; presented once that sheet has dismissed.
    @State private var pendingAction: PlanAction?

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
                    else if dietManager.dietData.isEmpty {
                        EmptyHubView(
                            kind: .diet,
                            isSubscribed: storeKit.isSubscribed,
                            canCreateAnother: canCreateAnotherPlan,
                            onAction: { perform($0) },
                            onShowLibrary: { withAnimation(.easeInOut(duration: 0.2)) { selectedView = .library } }
                        )
                    }
                    else { activePlanContent }
                case .library:
                    DietPlanLibraryView()
                        .environmentObject(dietManager)
                        .environmentObject(authManager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BulkUpColors.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingImport) {
            ImportPlanView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingActions, onDismiss: runPendingAction) {
            PlanActionsSheet(
                kind: .diet,
                isSubscribed: storeKit.isSubscribed,
                canCreateAnother: canCreateAnotherPlan,
                hasActivePlan: selectedView == .active && !dietManager.dietData.isEmpty,
                onAction: { pendingAction = $0 }
            )
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
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDiet)) { _ in
            // An imported diet lands on the plan, not the library.
            withAnimation(.easeInOut(duration: 0.2)) { selectedView = .active }
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
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.sm)
        .padding(.top, Spacing.md)
        .background(BulkUpColors.background)
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
        .background(BulkUpGround())
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .controlSize(.large)
                .tint(BulkUpColors.accent)

            Text("Cargando tu plan")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions (from the sheet and the empty hub)

    private func perform(_ action: PlanAction) {
        switch action {
        case .importFile:
            if storeKit.isSubscribed { showingImport = true } else { showingSubscription = true }
        case .manual:
            if canCreateAnotherPlan { showingDietPlanEditor = true } else { showingSubscription = true }
        case .foodPreferences:
            showingFoodPreferences = true
        case .template, .code, .exerciseLibrary:
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
