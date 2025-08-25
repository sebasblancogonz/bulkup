//
//  MainAppView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//
import SwiftData
import SwiftUI

struct MainAppView: View {
    let modelContext: ModelContext

    @EnvironmentObject var authManager: AuthManager
    @StateObject private var dietManager = DietManager.shared
    @StateObject private var trainingManager = TrainingManager.shared
    @StateObject private var storeKitManager = StoreKitManager.shared

    @State private var showingSubscriptionAlert = false
    @State private var showingSubscriptionView = false
    @State private var selectedTab: AppTab = .upload
    @State private var showingProfile = false
    @State private var showingNotifications = false

    private var userHasActiveSubscription: Bool {
        return storeKitManager.hasActiveSubscription
    }

    enum AppTab: String, CaseIterable, Identifiable {
        case upload = "upload"
        case diet = "diet"
        case training = "training"
        case rm = "rm"
        case exercises = "exercises"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .upload: return "Subir"
            case .diet: return "Dieta"
            case .training: return "Entrenamiento"
            case .rm: return "Mis RM"
            case .exercises: return "Ejercicios"
            }
        }

        var shortName: String {
            switch self {
            case .upload: return "Subir"
            case .diet: return "Dieta"
            case .training: return "Entreno"
            case .rm: return "RM"
            case .exercises: return "Ejercicios"
            }
        }

        var iconName: String {
            switch self {
            case .upload: return "plus.circle.fill"
            case .diet: return "fork.knife"
            case .training: return "dumbbell.fill"
            case .rm: return "chart.bar.fill"
            case .exercises: return "list.bullet"
            }
        }

        var gradient: LinearGradient {
            switch self {
            case .upload:
                return LinearGradient(
                    colors: [.purple, .purple.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case .diet:
                return LinearGradient(
                    colors: [.green, .green.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case .training:
                return LinearGradient(
                    colors: [.blue, .blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case .rm:
                return LinearGradient(
                    colors: [.orange, .orange.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case .exercises:
                return LinearGradient(
                    colors: [.pink, .pink.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }

        var primaryColor: Color {
            switch self {
            case .upload: return .purple
            case .diet: return .green
            case .training: return .blue
            case .rm: return .orange
            case .exercises: return .pink
            }
        }

        var isDisabled: Bool {
            switch self {
            case .upload, .rm, .exercises:
                return false
            case .diet, .training:
                return false  // Se evaluará dinámicamente en la vista
            }
        }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var body: some View {
        Group {
            if authManager.isLoadingUserData {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Cargando tus datos...")
                        .font(.headline)
                }
            } else {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        simplifiedHeaderView

                        if geometry.size.width > 600 {
                            tabNavigationView
                        }

                        contentView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .ignoresSafeArea(.keyboard)
                    }
                    .overlay(
                        Group {
                            if geometry.size.width <= 600 {
                                fixedMobileTabBar.ignoresSafeArea(
                                    .keyboard,
                                    edges: .bottom
                                )
                            }
                        },
                        alignment: .bottom
                    )
                }
                .environmentObject(dietManager)
                .environmentObject(trainingManager)
                .onReceive(
                    NotificationCenter.default.publisher(for: .userDidLogout)
                ) { _ in
                    showingProfile = false
                    showingNotifications = false
                    selectedTab = .upload
                }
                .sheet(isPresented: $showingProfile) {
                    ProfileView()
                        .environmentObject(authManager)
                }
                .sheet(isPresented: $showingNotifications) {
                    NotificationView()
                }.alert(
                    "Suscripción Requerida",
                    isPresented: $showingSubscriptionAlert
                ) {
                    Button("Ver Planes", role: nil) {
                        showingSubscriptionView = true
                    }
                    Button("Cancelar", role: .cancel) {}
                } message: {
                    Text(
                        "Necesitas una suscripción activa para subir y gestionar tus planes de entrenamiento y dieta."
                    )
                }
                .sheet(isPresented: $showingSubscriptionView) {
                    SubscriptionView()
                        .environmentObject(authManager)
                }
            }
        }
    }

    // MARK: - Header simplificado
    private var simplifiedHeaderView: some View {
        HStack {
            // ✅ Solo avatar + nombre
            Button(action: { showingProfile = true }) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(
                                authManager.user?.name.prefix(1).uppercased()
                                    ?? "U"
                            )
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        )
                    VStack(alignment: .leading, spacing: 0) {  // Cambiar alignment a .leading
                        Text(
                            "¡Hola \(authManager.user?.name.split(separator: " ").first.map(String.init) ?? "")!"
                        )
                        .font(.headline)
                        .fontWeight(.semibold)

                        Text("Lightweight baby!!! 💪")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // ✅ Indicadores compactos de estado + acciones
            HStack(spacing: 12) {
                // Indicador de dieta cargada
                if !dietManager.dietData.isEmpty {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.green)
                        .font(.title3)
                }

                // Indicador de entrenamiento cargado
                if !trainingManager.trainingData.isEmpty {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }

                // Notificaciones
                Button(action: { showingNotifications = true }) {
                    Image(systemName: "bell")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var fixedMobileTabBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    Button(action: {
                        if tab == .upload && !userHasActiveSubscription {
                            showingSubscriptionAlert = true
                        } else if !isTabDisabled(tab) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            ZStack(alignment: .topTrailing) {
                                Image(
                                    systemName: selectedTab == tab
                                        ? tab.iconName
                                        : tab.iconName.replacingOccurrences(
                                            of: ".fill",
                                            with: ""
                                        )
                                )
                                .font(
                                    .system(
                                        size: 20,
                                        weight: selectedTab == tab
                                            ? .semibold : .medium
                                    )
                                )
                                .foregroundColor(
                                    isTabDisabled(tab)
                                        ? .gray.opacity(0.4)
                                        : selectedTab == tab ? .blue : .gray
                                )

                                // Badge PRO para el tab de subir
                                if tab == .upload && !userHasActiveSubscription
                                {
                                    Text("PRO")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 3)
                                        .padding(.vertical, 1)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            .purple,
                                                            .purple.opacity(
                                                                0.8
                                                            ),
                                                        ],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        )
                                        .offset(x: 8, y: -5)
                                }
                            }

                            Text(tab.shortName)
                                .font(.caption2)
                                .fontWeight(
                                    selectedTab == tab ? .semibold : .medium
                                )
                                .foregroundColor(
                                    isTabDisabled(tab)
                                        ? .gray.opacity(0.4)
                                        : selectedTab == tab ? .blue : .gray
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .disabled(tab != .upload && isTabDisabled(tab))
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
    }

    private var tabNavigationView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AppTab.allCases) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        isDisabled: isTabDisabled(tab),
                        action: { selectedTab = tab }
                    )
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGray6).opacity(0.5))
    }

    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .upload:
            if userHasActiveSubscription {
                FileUploadView()
                    .environmentObject(dietManager)
                    .environmentObject(trainingManager)
                    .environmentObject(authManager)
            } else {
                SubscriptionRequiredView(
                    onSubscribe: {
                        showingSubscriptionView = true
                    }
                )
            }
        case .diet:
            if dietManager.dietData.isEmpty {
                EmptyStateView(
                    icon: "leaf.circle",
                    title: "Sin plan de dieta",
                    subtitle: "Sube tu plan de alimentación para comenzar",
                    actionTitle: "Subir Plan",
                    actionIcon: "plus.circle.fill",
                    color: .green
                ) {
                    if userHasActiveSubscription {
                        selectedTab = .upload
                    } else {
                        showingSubscriptionAlert = true
                    }
                }
            } else {
                NavigationStack {
                    DietView()
                        .environmentObject(authManager)
                        .environmentObject(dietManager)
                }
            }
        case .training:
            // UPDATED: Use the new TrainingHubView instead of checking for empty data
            NavigationStack {
                TrainingHubView()
                    .environmentObject(authManager)
                    .environmentObject(trainingManager)
            }
        case .rm:
            RMTrackerView()
                .environmentObject(authManager)
        case .exercises:
            ExerciseExplorerView()
                .environmentObject(authManager)
        }
    }

    // MARK: - Funciones auxiliares

    private func getSectionTitle() -> String {
        switch selectedTab {
        case .upload: return "Mi Plan Inteligente"
        case .diet: return "Mi Nutrición"
        case .training: return "Mi Entrenamiento"
        case .rm: return "Mis Récords"
        case .exercises: return "Explorar Ejercicios"
        }
    }

    private func getSectionSubtitle() -> String {
        switch selectedTab {
        case .upload: return "Sube y gestiona tus planes"
        case .diet: return "Plan alimentario personalizado"
        case .training: return "Rutina de ejercicios"
        case .rm: return "Seguimiento de máximos"
        case .exercises: return "Base de datos de ejercicios"
        }
    }

    private var hasData: Bool {
        switch selectedTab {
        case .upload:
            return !dietManager.dietData.isEmpty
                || !trainingManager.trainingData.isEmpty
        case .diet: return !dietManager.dietData.isEmpty
        case .training: return !trainingManager.trainingData.isEmpty
        case .rm, .exercises: return true
        }
    }

    private var shouldShowProgress: Bool {
        return !dietManager.dietData.isEmpty
            || !trainingManager.trainingData.isEmpty
    }

    private func isTabDisabled(_ tab: AppTab) -> Bool {
        switch tab {
        case .upload:
            return !userHasActiveSubscription
        case .diet:
            return dietManager.dietData.isEmpty
        case .training, .rm, .exercises:
            return false  // Training tab is never disabled now
        }
    }

}
