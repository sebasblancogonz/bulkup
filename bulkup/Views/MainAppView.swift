//
//  MainAppView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//
import SwiftData
import SwiftUI

// MARK: - App Tab Definition
enum AppTab: String, CaseIterable, Identifiable {
    case today
    case training
    case diet
    case profile

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: "Hoy"
        case .training: "Entreno"
        case .diet: "Dieta"
        case .profile: "Perfil"
        }
    }

    var icon: String {
        switch self {
        case .today: "house"
        case .training: "dumbbell"
        case .diet: "fork.knife"
        case .profile: "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .today: "house.fill"
        case .training: "dumbbell.fill"
        case .diet: "fork.knife"
        case .profile: "person.fill"
        }
    }
}

// MARK: - Main App View
struct MainAppView: View {
    let modelContext: ModelContext

    @AppStorage("hapticFeedback") private var hapticFeedback = true

    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var hapticManager = HapticManager.shared
    @ObservedObject private var dietManager = DietManager.shared
    @ObservedObject private var trainingManager = TrainingManager.shared
    @ObservedObject private var storeKitManager = StoreKitManager.shared
    @ObservedObject private var workoutSession = WorkoutSessionManager.shared

    @State private var selectedTab: AppTab = .today
    @State private var showingNotifications = false
    @State private var showWorkoutMenu = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var body: some View {
        Group {
            if authManager.isLoadingUserData {
                loadingView
            } else {
                ZStack(alignment: .bottom) {
                    TabView(selection: $selectedTab) {
                        Tab("Hoy", systemImage: "house.fill", value: .today) {
                            TodayView()
                                .environmentObject(authManager)
                                .toolbarVisibility(workoutSession.isActive ? .hidden : .automatic, for: .tabBar)
                        }

                        Tab("Entreno", systemImage: "dumbbell.fill", value: .training) {
                            NavigationStack {
                                TrainingHubView()
                                    .environmentObject(authManager)
                                    .environmentObject(trainingManager)
                            }
                            .toolbarVisibility(workoutSession.isActive ? .hidden : .automatic, for: .tabBar)
                        }

                        Tab("Dieta", systemImage: "fork.knife", value: .diet) {
                            NavigationStack {
                                DietHubView()
                                    .environmentObject(authManager)
                                    .environmentObject(dietManager)
                            }
                            .toolbarVisibility(workoutSession.isActive ? .hidden : .automatic, for: .tabBar)
                        }

                        Tab("Perfil", systemImage: "person.fill", value: .profile) {
                            NavigationStack {
                                UserProfileView()
                                    .environmentObject(authManager)
                            }
                            .toolbarVisibility(workoutSession.isActive ? .hidden : .automatic, for: .tabBar)
                        }
                    }
                    .tint(BulkUpColors.accent)

                    // Floating workout FAB when session active
                    if workoutSession.isActive {
                        workoutFAB
                    }
                }
                .environmentObject(dietManager)
                .environmentObject(trainingManager)
                .onReceive(
                    NotificationCenter.default.publisher(for: .userDidLogout)
                ) { _ in
                    showingNotifications = false
                    selectedTab = .today
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: .navigateToTraining)
                ) { _ in
                    selectedTab = .training
                }
                .onReceive(
                    NotificationCenter.default.publisher(for: .navigateToDiet)
                ) { _ in
                    selectedTab = .diet
                }
                .sheet(isPresented: $showingNotifications) {
                    NotificationView()
                }
            }
        }
    }

    // MARK: - Workout Floating Action Button

    private var workoutFAB: some View {
        VStack(spacing: 0) {
            Spacer()

            // Expanded menu items
            if showWorkoutMenu {
                workoutMenuItems
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.5, anchor: .bottom).combined(with: .opacity),
                        removal: .scale(scale: 0.5, anchor: .bottom).combined(with: .opacity)
                    ))
            }

            // Main circular button
            Button {
                if hapticFeedback {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showWorkoutMenu.toggle()
                }
            } label: {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(BulkUpColors.accent.opacity(0.15))
                        .frame(width: 72, height: 72)

                    // Main circle
                    Circle()
                        .fill(BulkUpColors.accent)
                        .frame(width: 60, height: 60)
                        .shadow(color: BulkUpColors.accent.opacity(0.4), radius: 12, y: 4)

                    if showWorkoutMenu {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(BulkUpColors.onAccent)
                    } else {
                        // Timer display inside button
                        VStack(spacing: 1) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(BulkUpColors.onAccent)

                            Text(workoutSession.formattedElapsed())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .monospacedDigit()
                                .foregroundColor(BulkUpColors.onAccent)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, Spacing.screenH)
    }

    // MARK: - Workout Menu Items

    private var workoutMenuItems: some View {
        VStack(spacing: Spacing.sm) {
            // Navigate to workout
            if selectedTab != .training {
                workoutMenuItem(
                    icon: "dumbbell.fill",
                    label: "Ir al entreno",
                    color: BulkUpColors.accent
                ) {
                    withAnimation { selectedTab = .training }
                    closeMenu()
                }
            }

            // Pause / Resume
            workoutMenuItem(
                icon: workoutSession.isPaused ? "play.fill" : "pause.fill",
                label: workoutSession.isPaused ? "Continuar" : "Pausar",
                color: BulkUpColors.warning
            ) {
                if workoutSession.isPaused {
                    workoutSession.resumeWorkout()
                } else {
                    workoutSession.pauseWorkout()
                }
                closeMenu()
            }

            // Finish
            workoutMenuItem(
                icon: "checkmark.circle.fill",
                label: "Finalizar",
                color: BulkUpColors.success
            ) {
                closeMenu()
                selectedTab = .training
                // Small delay so tab switch completes first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: .finishWorkoutSession, object: nil)
                }
            }

            // Discard
            workoutMenuItem(
                icon: "trash.fill",
                label: "Descartar",
                color: BulkUpColors.error
            ) {
                closeMenu()
                workoutSession.discardWorkout()
            }
        }
        .padding(.bottom, Spacing.sm)
    }

    private func workoutMenuItem(
        icon: String,
        label: LocalizedStringKey,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            if hapticFeedback {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            action()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())

                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: 180, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func closeMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showWorkoutMenu = false
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(BulkUpColors.accent)
            Text("Cargando tus datos...")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BulkUpColors.background.ignoresSafeArea())
    }
}
