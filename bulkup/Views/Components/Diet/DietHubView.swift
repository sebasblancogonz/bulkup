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
    @State private var selectedView: DietHubSection = .active
    @State private var showingCreateDietPlan = false

    enum DietHubSection: String, CaseIterable {
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
                    if dietManager.dietData.isEmpty {
                        activePlanEmptyState
                    } else {
                        DietView()
                            .environmentObject(dietManager)
                            .environmentObject(authManager)
                    }
                case .library:
                    DietPlanLibraryView()
                        .environmentObject(dietManager)
                        .environmentObject(authManager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: selectedView) { oldValue, newValue in
                if newValue == .active, let userId = authManager.user?.id {
                    Task {
                        await dietManager.loadActiveDietPlan(userId: userId)

                        if dietManager.dietPlanId == nil {
                            await MainActor.run {
                                dietManager.clearAllData()
                            }
                        }
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingCreateDietPlan) {
            CreateDietPlanView()
                .environmentObject(dietManager)
                .environmentObject(authManager)
        }
    }

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(DietHubSection.allCases, id: \.self) { section in
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
                            selectedView == section ? .green : .secondary
                        )

                        Rectangle()
                            .fill(
                                selectedView == section
                                    ? Color.green : Color.clear
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
                Button {
                    showingCreateDietPlan = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
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
                                    .green.opacity(0.2), .green.opacity(0.05),
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
                                colors: [.green, .green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .green.opacity(0.2), radius: 20, x: 0, y: 10)
            }

            VStack(spacing: 12) {
                Text("No tienes un plan activo")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Sube un nuevo plan o activa uno desde tu biblioteca")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            VStack(spacing: 12) {
                Button {
                    showingCreateDietPlan = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.badge.plus")
                            .font(.title3)

                        Text("Subir Plan de Dieta")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
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
        .onAppear {
            if !dietManager.isLoading, let userId = authManager.user?.id {
                Task {
                    await dietManager.loadActiveDietPlan(userId: userId)
                }
            }
        }
    }
}

// MARK: - Diet Plan Library View
struct DietPlanLibraryView: View {
    @EnvironmentObject var dietManager: DietManager
    @EnvironmentObject var authManager: AuthManager
    @State private var dietPlans: [DietPlan] = []
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
            } else if dietPlans.isEmpty {
                libraryEmptyState
            } else {
                plansList.padding(.bottom, 55)
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
                Text("Biblioteca vacia")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Sube tu primer plan de dieta")
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

                    Text("Subir Plan")
                        .fontWeight(.semibold)
                }
                .frame(width: 200, height: 44)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingCreatePlan) {
            CreateDietPlanView()
                .environmentObject(dietManager)
                .environmentObject(authManager)
        }
    }

    private var plansList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
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
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }

            // Plan Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(
                        "\(plan.dietDays.count) dias",
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Spacer()

                    Text("Creado \(plan.createdAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let totalMeals = plan.dietDays.first?.mealCount {
                    Label(
                        "\(totalMeals) comidas por dia",
                        systemImage: "fork.knife"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                // Day name chips preview
                if !plan.dietDays.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(plan.dietDays.prefix(5), id: \.day) { day in
                                Text(day.day.capitalized)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }

                            if plan.dietDays.count > 5 {
                                Text("+\(plan.dietDays.count - 5)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
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
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .contentShape(Rectangle())
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
