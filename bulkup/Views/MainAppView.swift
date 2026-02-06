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

    @AppStorage("hapticFeedback") private var hapticFeedback = true

    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var hapticManager = HapticManager.shared
    @ObservedObject private var dietManager = DietManager.shared
    @ObservedObject private var trainingManager = TrainingManager.shared
    @ObservedObject private var storeKitManager = StoreKitManager.shared

    @State private var showingSubscriptionAlert = false
    @State private var showingSubscriptionView = false
    @State private var selectedTab: AppTab = .training
    @State private var showingProfile = false
    @State private var showingNotifications = false

    private var userHasActiveSubscription: Bool {
        return storeKitManager.hasActiveSubscription
    }

    enum AppTab: String, CaseIterable, Identifiable {
        case diet = "diet"
        case training = "training"
        case rm = "rm"
        case exercises = "exercises"
        case profile = "perfil"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .profile: return "Perfil"
            case .diet: return "Dieta"
            case .training: return "Entrenamiento"
            case .rm: return "Mis RM"
            case .exercises: return "Ejercicios"
            }
        }

        var shortName: String {
            switch self {
            case .profile: return "Perfil"
            case .diet: return "Dieta"
            case .training: return "Entreno"
            case .rm: return "RM"
            case .exercises: return "Ejercicios"
            }
        }

        var iconName: String {
            switch self {
            case .diet: return "fork.knife"
            case .training: return "dumbbell.fill"
            case .rm: return "chart.bar.fill"
            case .exercises: return "list.bullet"
            case .profile: return "person.circle.fill"
            }
        }

        var gradient: LinearGradient {
            switch self {
            
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
            case .profile:
                return LinearGradient(
                    colors: [.pink, .pink.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }

        var primaryColor: Color {
            switch self {
            case .diet: return .green
            case .training: return .blue
            case .rm: return .orange
            case .exercises: return .pink
            case .profile: return .teal
            }
        }

        var isDisabled: Bool {
            switch self {
            case .rm, .exercises, .profile:
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
                    ZStack(alignment: .bottom) {
                        VStack(spacing: 0) {
                            if geometry.size.width > 600 {
                                tabNavigationView
                            }

                            contentView
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }

                        if geometry.size.width <= 600 {
                            fixedMobileTabBar
                                .ignoresSafeArea(.keyboard, edges: .bottom) // fijo abajo
                        }
                    }
                }
                .environmentObject(dietManager)
                .environmentObject(trainingManager)
                .onReceive(
                    NotificationCenter.default.publisher(for: .userDidLogout)
                ) { _ in
                    showingProfile = false
                    showingNotifications = false
                    selectedTab = .training
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

    private var fixedMobileTabBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(AppTab.allCases.filter { $0 != .profile }) { tab in
                    Button(action: {
                        HapticManager.shared.trigger(
                            .medium,
                            enabled: hapticFeedback
                        )
                        if !isTabDisabled(tab) {
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
                    .disabled(isTabDisabled(tab))
                    .buttonStyle(PlainButtonStyle())
                }

                Button(action: {
                    HapticManager.shared.trigger(
                        .medium,
                        enabled: hapticFeedback
                    )
                    selectedTab = .profile
                }) {
                    VStack(spacing: 4) {

                        // Avatar or person icon
                        if let urlString = authManager.user?.profileImageURL,
                            let url = URL(string: urlString)
                        {
                            CachedAsyncImage(
                                url: url,
                                content: { image, colors in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 24, height: 24)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    selectedTab == .profile
                                                        ? Color.teal
                                                        : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                },
                                placeholder: {
                                    profileIconPlaceholder
                                }
                            )
                        } else {
                            profileIconPlaceholder
                        }

                        Text("Perfil")
                            .font(.caption2)
                            .fontWeight(
                                selectedTab == .profile ? .semibold : .medium
                            )
                            .foregroundColor(
                                selectedTab == .profile ? .teal : .gray
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
    }

    private var profileIconPlaceholder: some View {
        ZStack {
            Circle()
                .fill(
                    selectedTab == .profile
                        ? Color.teal : Color.gray.opacity(0.3)
                )
                .frame(width: 24, height: 24)

            Text(authManager.user?.name.prefix(1).uppercased() ?? "U")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
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
                        selectedTab = .training
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
        case .profile:
            NavigationStack {
                UserProfileView()
                    .environmentObject(authManager)
            }
        case .rm:
            RMTrackerView()
                .environmentObject(authManager)
        case .exercises:
            ExerciseExplorerView()
                .environmentObject(authManager)
        }
    }

    private func isTabDisabled(_ tab: AppTab) -> Bool {
        switch tab {
        case .diet:
            return dietManager.dietData.isEmpty
        case .training, .rm, .exercises, .profile:
            return false  // Training tab is never disabled now
        }
    }

}
