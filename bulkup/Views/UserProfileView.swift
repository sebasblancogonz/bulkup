//
//  UserProfileView.swift
//  bulkup
//
//  Created by sebastian.blanco on 11/9/25.
//

import PhotosUI
import SwiftUI
import UserNotifications

struct UserProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var storeKitManager = StoreKitManager.shared
    @ObservedObject private var dietManager = DietManager.shared
    @ObservedObject private var trainingManager = TrainingManager.shared
    @ObservedObject private var measurementsManager = BodyMeasurementsManager.shared
    @ObservedObject private var friendsManager = FriendsManager.shared

    @State private var showingEditProfile = false
    @State private var showingBodyMeasurements = false
    @State private var showingSettings = false
    @State private var showingSubscription = false
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingImagePicker = false
    @State private var showingExportShare = false
    @State private var exportFileURL: URL?
    @State private var selectedImage: PhotosPickerItem?
    @State private var animateStats = false

    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("notifications") private var notificationsEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionGap) {
                // Profile Header
                profileHeaderSection

                // Stats Section
                statsSection

                // Menu Options
                menuSection

                // Settings Section
                settingsSection

                // Account Actions
                accountActionsSection

                // App Version
                appVersionSection

                // Bottom spacer for floating tab bar
                Color.clear.frame(height: 80)
            }
            .padding(.horizontal, Spacing.screenH)
        }
        .scrollIndicators(.hidden)
        .background(BulkUpColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await friendsManager.loadMyStreak()
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateStats = true
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingBodyMeasurements) {
            NavigationStack {
                BodyMeasurementsView()
                    .environmentObject(authManager)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
                .environmentObject(authManager)
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedImage,
            matching: .images
        )
        .onChange(of: selectedImage) { _, newValue in
            if let newValue = newValue {
                loadImage(from: newValue)
            }
        }
        .alert("Cerrar Sesión", isPresented: $showingLogoutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Cerrar Sesión", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("¿Estás seguro de que quieres cerrar sesión?")
        }
        .sheet(isPresented: $showingExportShare) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Eliminar Cuenta", isPresented: $showingDeleteAccountAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text(
                "Esta acción es permanente y no se puede deshacer. Se eliminarán todos tus datos."
            )
        }
    }

    // MARK: - Profile Header

    private var profileHeaderSection: some View {
        VStack(spacing: Spacing.md) {
            // Top bar: spacer + settings gear
            HStack {
                Spacer()
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(BulkUpColors.surfaceElevated)
                        .clipShape(Circle())
                }
            }
            .padding(.top, Spacing.sm)

            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let urlString = authManager.user?.safeProfileImageURL,
                    let url = URL(string: urlString)
                {
                    CachedAsyncImage(
                        url: url,
                        content: { image, colors in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(BulkUpColors.accentGradient, lineWidth: 2)
                                )
                        },
                        placeholder: {
                            avatarPlaceholder
                        }
                    )
                } else {
                    avatarPlaceholder
                }
            }

            // Name
            Text(authManager.user?.name ?? "Usuario")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(BulkUpColors.textPrimary)

            // Email
            Text(authManager.user?.email ?? "")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(BulkUpColors.textSecondary)

            // Plan badge
            HStack(spacing: 5) {
                Image(
                    systemName: storeKitManager.hasActiveSubscription
                        ? "checkmark.seal.fill" : "lock.fill"
                )
                .font(.system(size: 11, weight: .bold))

                Text(
                    storeKitManager.hasActiveSubscription
                        ? "PRO" : "Plan Básico"
                )
                .font(BulkUpFont.badge())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                storeKitManager.hasActiveSubscription
                    ? BulkUpColors.accent.opacity(0.12)
                    : BulkUpColors.surfaceElevated
            )
            .foregroundColor(
                storeKitManager.hasActiveSubscription
                    ? BulkUpColors.accent
                    : BulkUpColors.textSecondary
            )
            .clipShape(Capsule())
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [BulkUpColors.accent, BulkUpColors.accentMuted],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 100, height: 100)
            .overlay(
                Text(authManager.user?.name.prefix(1).uppercased() ?? "U")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            )
            .overlay(
                Circle()
                    .stroke(BulkUpColors.accentGradient, lineWidth: 2)
            )
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ProfileStatCard(
                    title: "Días activo",
                    value: calculateDaysActive(),
                    icon: "calendar",
                    color: BulkUpColors.accent,
                    animated: animateStats
                )

                ProfileStatCard(
                    title: "Entrenamientos",
                    value: calculateWorkouts(),
                    icon: "dumbbell",
                    color: BulkUpColors.accent,
                    animated: animateStats
                )

                ProfileStatCard(
                    title: "Racha",
                    value: calculateStreak(),
                    icon: "flame.fill",
                    color: calculateStreak() > 0 ? BulkUpColors.accent : BulkUpColors.textTertiary,
                    dimmed: calculateStreak() == 0,
                    animated: animateStats
                )
            }
        }
    }

    // MARK: - Menu Section

    private var menuSection: some View {
        VStack(spacing: Spacing.sm) {
            MenuRow(
                title: "Editar Perfil",
                icon: "person.circle",
                color: BulkUpColors.accent,
                action: { showingEditProfile = true }
            )

            MenuRow(
                title: "Medidas Corporales",
                icon: "figure.arms.open",
                color: BulkUpColors.accent,
                showBadge: !storeKitManager.hasActiveSubscription,
                action: { showingBodyMeasurements = true }
            )

            MenuRow(
                title: "Mi Suscripción",
                icon: "crown",
                color: BulkUpColors.accent,
                showBadge: !storeKitManager.hasActiveSubscription,
                action: { showingSubscription = true }
            )

            MenuRow(
                title: "Historial de Pagos",
                icon: "creditcard",
                color: BulkUpColors.accent,
                action: {
                    Task {
                        await storeKitManager.openSubscriptionManagement()
                    }
                }
            )

            MenuRow(
                title: "Exportar Datos",
                icon: "square.and.arrow.up",
                color: BulkUpColors.accent,
                action: { exportUserData() }
            )
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("CONFIGURACIÓN")
                .font(BulkUpFont.sectionLabel())
                .tracking(1.5)
                .foregroundColor(BulkUpColors.textSecondary)

            VStack(spacing: Spacing.sm) {
                SettingRow(
                    title: "Vibración háptica",
                    icon: "iphone.radiowaves.left.and.right",
                    isOn: $hapticFeedback
                )

                SettingRow(
                    title: "Notificaciones",
                    icon: "bell",
                    isOn: Binding(
                        get: { notificationsEnabled },
                        set: { newValue in
                            notificationsEnabled = newValue
                            if newValue {
                                requestNotificationPermission()
                            }
                        }
                    )
                )
            }
        }
    }

    // MARK: - Account Actions

    private var accountActionsSection: some View {
        VStack(spacing: Spacing.md) {
            Button(action: { showingLogoutAlert = true }) {
                Text("Cerrar Sesión")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.error)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(BulkUpColors.error.opacity(0.08))
                    .cornerRadius(CornerRadius.medium)
            }

            Button(action: { showingDeleteAccountAlert = true }) {
                Text("Eliminar Cuenta")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)
            }
        }
    }

    // MARK: - App Version

    private var appVersionSection: some View {
        VStack(spacing: Spacing.xs) {
            Text("BulkUp · v\(Bundle.main.appVersion)")
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textTertiary)
        }
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Helper Functions

    private func loadImage(from item: PhotosPickerItem) {
        Task {
            // Load and upload image logic
        }
    }

    private func deleteAccount() async {
        // Delete account logic
    }

    private func calculateDaysActive() -> Int {
        if let createdAt = authManager.user?.createdAt {
            let days =
                Calendar.current.dateComponents(
                    [.day],
                    from: createdAt,
                    to: Date()
                ).day ?? 0
            return max(1, days)
        }
        return 1
    }

    private func calculateWorkouts() -> Int {
        return friendsManager.myStreak?.totalDays ?? 0
    }

    private func calculateStreak() -> Int {
        return friendsManager.myStreak?.currentStreak ?? 0
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
            granted, _ in
            DispatchQueue.main.async {
                if !granted {
                    notificationsEnabled = false
                }
            }
        }
    }

    // MARK: - Export Data

    private func exportUserData() {
        var exportData: [String: Any] = [:]
        let dateFormatter = ISO8601DateFormatter()

        // User profile
        if let user = authManager.user {
            var userData: [String: Any] = [
                "nombre": user.name,
                "email": user.email,
                "creadoEn": dateFormatter.string(from: user.createdAt),
            ]
            if let dob = user.dateOfBirth {
                userData["fechaDeNacimiento"] = dateFormatter.string(from: dob)
            }
            exportData["perfil"] = userData
        }

        // Diet data
        if !dietManager.dietData.isEmpty {
            let dietDays = dietManager.dietData.map { day -> [String: Any] in
                var dayData: [String: Any] = ["dia": day.day]
                dayData["comidas"] = day.meals.map { meal -> [String: Any] in
                    var mealData: [String: Any] = [
                        "tipo": meal.type,
                        "hora": meal.time,
                        "orden": meal.order,
                    ]
                    if let notes = meal.notes { mealData["notas"] = notes }
                    mealData["opciones"] = meal.options.map { option -> [String: Any] in
                        [
                            "descripcion": option.optionDescription,
                            "ingredientes": option.ingredients,
                            "instrucciones": option.instructions,
                        ]
                    }
                    return mealData
                }
                dayData["suplementos"] = day.supplements.map { supp -> [String: Any] in
                    var suppData: [String: Any] = [
                        "nombre": supp.name,
                        "dosis": supp.dosage,
                        "momento": supp.timing,
                        "frecuencia": supp.frequency,
                    ]
                    if let notes = supp.notes { suppData["notas"] = notes }
                    return suppData
                }
                return dayData
            }
            exportData["dieta"] = dietDays
        }

        // Training data
        if !trainingManager.trainingData.isEmpty {
            let trainingDays = trainingManager.trainingData.map { day -> [String: Any] in
                var dayData: [String: Any] = ["dia": day.day]
                if let name = day.workoutName { dayData["nombreEntrenamiento"] = name }
                dayData["ejercicios"] = day.exercises.map { ex -> [String: Any] in
                    var exData: [String: Any] = [
                        "nombre": ex.name,
                        "series": ex.sets,
                        "repeticiones": ex.reps,
                        "descansoSegundos": ex.restSeconds,
                    ]
                    if let notes = ex.notes { exData["notas"] = notes }
                    if let tempo = ex.tempo { exData["tempo"] = tempo }
                    return exData
                }
                return dayData
            }
            exportData["entrenamiento"] = trainingDays
        }

        // Body measurements
        if let measurements = measurementsManager.currentMeasurements {
            var measData: [String: Any] = [
                "peso": measurements.peso,
                "altura": measurements.altura,
                "edad": measurements.edad,
                "sexo": measurements.sexo,
                "cintura": measurements.cintura,
                "cuello": measurements.cuello,
            ]
            if let cadera = measurements.cadera { measData["cadera"] = cadera }
            if let brazo = measurements.brazo { measData["brazo"] = brazo }
            if let muslo = measurements.muslo { measData["muslo"] = muslo }
            if let pantorrilla = measurements.pantorrilla { measData["pantorrilla"] = pantorrilla }
            exportData["medidas"] = measData
        }

        if !measurementsManager.measurementsHistory.isEmpty {
            exportData["historialMedidas"] = measurementsManager.measurementsHistory.map {
                m -> [String: Any] in
                var d: [String: Any] = [
                    "peso": m.peso, "altura": m.altura,
                    "fecha": dateFormatter.string(from: m.fecha),
                ]
                if let cadera = m.cadera { d["cadera"] = cadera }
                if let brazo = m.brazo { d["brazo"] = brazo }
                return d
            }
        }

        exportData["fechaExportacion"] = dateFormatter.string(from: Date())

        // Write JSON file and present share sheet
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                "BulkUp_Export.json")
            try jsonData.write(to: tempURL)
            exportFileURL = tempURL
            showingExportShare = true
        } catch {
            print("Error exporting data: \(error)")
        }
    }
}

// MARK: - Profile Stat Card (120x140, premium)

struct ProfileStatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    var dimmed: Bool = false
    var animated: Bool = false

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text("\(animated ? value : 0)")
                .font(BulkUpFont.heroStatMedium())
                .foregroundColor(dimmed ? BulkUpColors.textTertiary : BulkUpColors.textPrimary)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.6), value: animated)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(width: 120, height: 140)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(BulkUpColors.surface)

                // Subtle inner glow
                RadialGradient(
                    colors: [color.opacity(0.03), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 100
                )
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Menu Row

struct MenuRow: View {
    let title: String
    let icon: String
    let color: Color
    var showBadge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(BulkUpColors.accent)
                    .frame(width: 24)

                Text(title)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)

                Spacer()

                if showBadge {
                    Text("UPGRADE")
                        .font(BulkUpFont.badge())
                        .foregroundColor(BulkUpColors.onAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(BulkUpColors.accent)
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(BulkUpColors.textTertiary)
            }
            .padding(Spacing.md)
            .background(BulkUpColors.surface)
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Setting Row

struct SettingRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(BulkUpColors.accent)
                .frame(width: 24)

            Text(title)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(BulkUpColors.accent)
        }
        .padding(Spacing.md)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
