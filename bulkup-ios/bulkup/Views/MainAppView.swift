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
    case progress
    case profile

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: "Hoy"
        case .training: "Entreno"
        case .diet: "Dieta"
        case .progress: "Progreso"
        case .profile: "Perfil"
        }
    }

    var icon: String {
        switch self {
        case .today: "house"
        case .training: "dumbbell"
        case .diet: "fork.knife"
        case .progress: "chart.bar"
        case .profile: "person"
        }
    }

    var selectedIcon: String {
        switch self {
        case .today: "house.fill"
        case .training: "dumbbell.fill"
        case .diet: "fork.knife"
        case .progress: "chart.bar.fill"
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
    @State private var showDiscardConfirm = false

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

                        Tab("Progreso", systemImage: "chart.bar.fill", value: .progress) {
                            // ProgressDashboardView wraps its own NavigationStack — don't nest another.
                            ProgressDashboardView()
                                .environmentObject(authManager)
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
                    .tint(BulkUpColors.accentText)

                    // Floating workout FAB when session active (hidden while summary is shown)
                    // Not on the Entreno tab: the header there already carries the session.
                    if workoutSession.isActive && !workoutSession.showSummary && selectedTab != .training {
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
                .onReceive(
                    NotificationCenter.default.publisher(for: .navigateToProgress)
                ) { _ in
                    selectedTab = .progress
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
                    // Floating control: the one earned shadow on the screen.
                    RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                        .fill(BulkUpColors.accent)
                        .frame(width: 64, height: 64)
                        .shadow(color: BulkUpColors.shadow.opacity(0.35), radius: 14, x: 0, y: 8)

                    if showWorkoutMenu {
                        Image(systemName: "xmark")
                            .font(.system(.title3, weight: .bold))
                            .foregroundColor(BulkUpColors.onAccent)
                    } else {
                        // Timer display inside button
                        VStack(spacing: 2) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(.callout, weight: .bold))
                                .foregroundColor(BulkUpColors.onAccent)

                            FABElapsedLabel()
                        }
                    }
                }
                .accessibilityLabel("Entreno en curso")
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, Spacing.screenH)
        .alert("¿Descartar entreno?", isPresented: $showDiscardConfirm) {
            Button("Descartar", role: .destructive) { workoutSession.discardWorkout() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se perderá todo el progreso de esta sesión.")
        }
    }

    /// Isolated so the 1 Hz elapsed tick re-renders only this label,
    /// not the whole tab container.
    private struct FABElapsedLabel: View {
        @ObservedObject private var ticker = WorkoutSessionManager.shared.ticker

        var body: some View {
            Text(WorkoutSessionManager.shared.formattedElapsed())
                .font(BulkUpFont.numeric(.caption2, weight: .bold))
                .foregroundColor(BulkUpColors.onAccent)
        }
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
                showDiscardConfirm = true
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
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))

                Text(label)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: 180, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(.ultraThinMaterial)
            )
            .lift(CornerRadius.medium)
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
                .tint(BulkUpColors.accentText)
            Text("Cargando tus datos...")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BulkUpColors.background.ignoresSafeArea())
    }
}
