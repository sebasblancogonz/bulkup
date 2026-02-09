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

    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingSubscription = false
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingImagePicker = false
    @State private var showingExportShare = false
    @State private var exportFileURL: URL?
    @State private var selectedImage: PhotosPickerItem?

    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("notifications") private var notificationsEnabled = true
    @AppStorage("theme") private var theme = "system"

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
            }
            .padding()
        }
        .navigationTitle("Mi Perfil")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authManager)
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
        VStack(spacing: 16) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if let urlString = authManager.user?.profileImageURL,
                    let url = URL(string: urlString)
                {
                    CachedAsyncImage(
                        url: url,
                        content: { image, colors in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        },
                        placeholder: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Text(authManager.user?.name.prefix(1).uppercased() ?? "U")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    )
                } else {
                    avatarPlaceholder
                }
            }

            // User Info
            VStack(spacing: 8) {
                Text(authManager.user?.name ?? "Usuario")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(authManager.user?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Subscription Status
                HStack(spacing: 4) {
                    Image(
                        systemName: storeKitManager.hasActiveSubscription
                            ? "checkmark.seal.fill" : "lock.fill"
                    )
                    .font(.caption)

                    Text(
                        storeKitManager.hasActiveSubscription
                            ? "PRO" : "Plan Básico"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    storeKitManager.hasActiveSubscription
                        ? Color.green.opacity(0.2)
                        : Color.gray.opacity(0.2)
                )
                .foregroundColor(
                    storeKitManager.hasActiveSubscription
                        ? .green
                        : .secondary
                )
                .cornerRadius(12)
            }
        }
        .padding(.vertical)
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.blue, .blue.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 100, height: 100)
            .overlay(
                Text(authManager.user?.name.prefix(1).uppercased() ?? "U")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 16) {
            ProfileStatCard(
                title: "Días activo",
                value: "\(calculateDaysActive())",
                icon: "calendar",
                color: .blue
            )

            ProfileStatCard(
                title: "Entrenamientos",
                value: "\(calculateWorkouts())",
                icon: "dumbbell",
                color: .green
            )

            ProfileStatCard(
                title: "Racha",
                value: "\(calculateStreak())",
                icon: "flame",
                color: .orange
            )
        }
    }

    // MARK: - Menu Section

    private var menuSection: some View {
        VStack(spacing: 12) {
            MenuRow(
                title: "Editar Perfil",
                icon: "person.circle",
                color: .blue,
                action: { showingEditProfile = true }
            )

            MenuRow(
                title: "Mi Suscripción",
                icon: "crown",
                color: .purple,
                showBadge: !storeKitManager.hasActiveSubscription,
                action: { showingSubscription = true }
            )

            MenuRow(
                title: "Historial de Pagos",
                icon: "creditcard",
                color: .green,
                action: {
                    Task {
                        await storeKitManager.openSubscriptionManagement()
                    }
                }
            )

            MenuRow(
                title: "Exportar Datos",
                icon: "square.and.arrow.up",
                color: .orange,
                action: { exportUserData() }
            )
        }
        .padding(.vertical, 8)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuración")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
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

                SettingRow(
                    title: "Modo oscuro",
                    icon: "moon",
                    isOn: Binding(
                        get: { theme == "dark" },
                        set: { newValue in
                            theme = newValue ? "dark" : "system"
                            applyTheme(theme)
                        }
                    )
                )
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Account Actions

    private var accountActionsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showingLogoutAlert = true }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Cerrar Sesión")
                    Spacer()
                }
                .foregroundColor(.orange)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }

            Button(action: { showingDeleteAccountAlert = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Eliminar Cuenta")
                    Spacer()
                }
                .foregroundColor(.red)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - App Version

    private var appVersionSection: some View {
        VStack(spacing: 8) {
            Text("BulkUp")
                .font(.caption)
                .fontWeight(.semibold)

            Text("Versión \(Bundle.main.appVersion)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("© 2025 BulkUp")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
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
        // Calculate days since account creation
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
        // Return number of completed workouts
        return 0  // Implement based on your data
    }

    private func calculateStreak() -> Int {
        // Return current streak
        return 0  // Implement based on your data
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

    // MARK: - Theme

    private func applyTheme(_ theme: String) {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else { return }

        switch theme {
        case "light":
            window.overrideUserInterfaceStyle = .light
        case "dark":
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
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

// MARK: - Supporting Views

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MenuRow: View {
    let title: String
    let icon: String
    let color: Color
    var showBadge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                if showBadge {
                    Text("UPGRADE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple)
                        .cornerRadius(4)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(title)
                .font(.body)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
