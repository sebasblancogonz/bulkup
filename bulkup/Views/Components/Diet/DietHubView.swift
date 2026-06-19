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
    @State private var showingCreateDietPlan = false
    @State private var showingDietPlanEditor = false
    @State private var showingSubscription = false
    @State private var showingLibrarySheet = false

    var body: some View {
        VStack(spacing: 0) {
            if dietManager.isLoading {
                loadingView
            } else if dietManager.dietData.isEmpty {
                activePlanEmptyState
            } else {
                activePlanContent
            }
        }
        .background(BulkUpColors.background)
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
        .sheet(isPresented: $showingLibrarySheet) {
            NavigationStack {
                DietPlanLibraryView()
                    .environmentObject(dietManager)
                    .environmentObject(authManager)
                    .navigationTitle("Mis Planes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cerrar") {
                                showingLibrarySheet = false
                            }
                            .foregroundColor(BulkUpColors.diet)
                        }

                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu {
                                Button {
                                    showingLibrarySheet = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        if storeKit.isSubscribed {
                                            showingCreateDietPlan = true
                                        } else {
                                            showingSubscription = true
                                        }
                                    }
                                } label: {
                                    Label("Importar con IA", systemImage: "sparkles")
                                }

                                Button {
                                    showingLibrarySheet = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showingDietPlanEditor = true
                                    }
                                } label: {
                                    Label("Crear manualmente", systemImage: "square.and.pencil")
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(BulkUpColors.diet)
                            }
                        }
                    }
            }
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
            showingLibrarySheet = true
        }
    }

    // MARK: - Plan Header

    private var planHeader: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(dietManager.activePlanName ?? String(localized: "Plan de Dieta"))
                    .font(BulkUpFont.sectionHeader())
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(1)

                Text("\(dietManager.dietData.count) dias · \(totalMealCount) comidas")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            Spacer()

            Menu {
                Button {
                    showingLibrarySheet = true
                } label: {
                    Label("Mis Planes", systemImage: "folder.fill")
                }

                Divider()

                Button {
                    if storeKit.isSubscribed {
                        showingCreateDietPlan = true
                    } else {
                        showingSubscription = true
                    }
                } label: {
                    Label("Importar con IA", systemImage: "sparkles")
                }

                Button {
                    showingDietPlanEditor = true
                } label: {
                    Label("Crear manualmente", systemImage: "square.and.pencil")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(BulkUpColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    private var totalMealCount: Int {
        dietManager.dietData.first?.meals.count ?? 0
    }

    // MARK: - Active Plan Content

    private var activePlanContent: some View {
        VStack(spacing: 0) {
            planHeader

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
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        BulkUpColors.diet.opacity(0.2), BulkUpColors.diet.opacity(0.05),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)

                        Image(systemName: "leaf.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [BulkUpColors.diet, BulkUpColors.diet.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .shadow(color: BulkUpColors.diet.opacity(0.2), radius: 20, x: 0, y: 10)
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
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [BulkUpColors.diet.opacity(0.2), BulkUpColors.diet.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(BulkUpColors.diet)
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
                                            .foregroundColor(BulkUpColors.onAccent)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(BulkUpColors.secondary)
                                            .cornerRadius(4)
                                    }
                                }

                                Text("Sube un PDF o foto de tu dieta")
                                    .font(BulkUpFont.body())
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: storeKit.isSubscribed ? "chevron.right" : "lock.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(storeKit.isSubscribed ? BulkUpColors.diet.opacity(0.5) : BulkUpColors.secondary.opacity(0.6))
                        }
                        .padding(Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.large)
                                .fill(BulkUpColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.large)
                                .stroke(BulkUpColors.diet.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: BulkUpColors.diet.opacity(0.15), radius: 8, x: 0, y: 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Crear manualmente
                    Button {
                        showingDietPlanEditor = true
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
                    showingLibrarySheet = true
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "folder.fill")
                            .font(BulkUpFont.body())

                        Text("Ver Mis Planes")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(BulkUpColors.diet)
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
                Circle()
                    .fill(BulkUpColors.surfaceElevated)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(BulkUpColors.diet)
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
        .padding(.horizontal, Spacing.screenH)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(BulkUpColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(BulkUpColors.surfaceElevated, lineWidth: 1)
        )
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
                            } ?? []
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

    @State private var showingDeleteAlert = false
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
                                .fill(BulkUpColors.diet)
                                .frame(width: 8, height: 8)
                            Text("Plan Activo")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.diet)
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
                        "\(plan.dietDays.count) dias",
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
                                Text(day.day.capitalized)
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
                .foregroundColor(BulkUpColors.onAccent)
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
    }
}

// MARK: - Supporting Models
struct DietPlan: Identifiable {
    let id: String
    let name: String
    var isActive: Bool
    let createdAt: Date
    let dietDays: [DietDaySummary]
}

struct DietDaySummary {
    let day: String
    let mealCount: Int
    let supplementCount: Int
}
