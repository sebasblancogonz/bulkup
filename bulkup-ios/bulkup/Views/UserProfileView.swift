//
//  UserProfileView.swift
//  bulkup
//
//  The Perfil tab: who you are, your streak in numbers, your account as
//  rows, your friends as rows you can open. Graphite & Voltage.
//

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
    @State private var showingDeleteAccountError = false
    @State private var deleteAccountErrorMessage = ""
    @State private var showingExportShare = false
    @State private var exportFileURL: URL?
    @State private var showingAddFriend = false
    @State private var showingMyCode = false
    @State private var selectedFriend: FriendProfile?

    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("notifications") private var notificationsEnabled = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                statsStrip
                accountSlab
                friendsSlab
                quickSettingsSlab
                accountActions
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.md)
            .padding(.bottom, 100)
        }
        .background(BulkUpGround())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            // The toggle reflects the system permission, not a stored preference.
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .denied || settings.authorizationStatus == .notDetermined {
                notificationsEnabled = false
            }
            await friendsManager.loadLeaderboard()
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
        .sheet(isPresented: $showingAddFriend) {
            AddFriendView().environmentObject(authManager)
        }
        .sheet(isPresented: $showingMyCode) {
            MyFriendCodeView()
        }
        .sheet(item: $selectedFriend) { friend in
            FriendProfileView(friend: friend)
        }
        .sheet(isPresented: $showingExportShare) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Cerrar sesión", isPresented: $showingLogoutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Cerrar sesión", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Tus datos siguen en tu cuenta; vuelve a entrar cuando quieras.")
        }
        .alert("Eliminar cuenta", isPresented: $showingDeleteAccountAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text(
                "Esta acción es permanente y no se puede deshacer. Se eliminarán todos tus datos. Si tienes una suscripción comprada a través de Apple, debes cancelarla por separado en los ajustes del App Store: eliminar la cuenta no la cancela."
            )
        }
        .alert("No se pudo eliminar la cuenta", isPresented: $showingDeleteAccountError) {
            Button("OK") {}
        } message: {
            Text(deleteAccountErrorMessage)
        }
    }

    // MARK: - Header: avatar, name, tier, settings square

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ProfileAvatar(name: authManager.user?.name ?? "", url: authManager.user?.safeProfileImageURL, size: 64)

            VStack(alignment: .leading, spacing: 2) {
                Text(authManager.user?.name ?? NSLocalizedString("Usuario", comment: ""))
                    .titleVoice(.title)
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(2)
                Text(authManager.user?.email ?? "")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if storeKitManager.hasActiveSubscription {
                    HStack(spacing: 6) {
                        ProTag()
                        Text("Suscripción activa")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                    .padding(.top, 4)
                } else {
                    Button { showingSubscription = true } label: {
                        Text("Plan básico · Pasar a PRO")
                            .font(.system(.footnote, weight: .semibold))
                            .foregroundColor(BulkUpColors.accentText)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: Spacing.sm)

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(BulkUpColors.textPrimary)
                    .frame(width: 46, height: 46)
                    .background(BulkUpColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    .lift(CornerRadius.medium)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ajustes")
        }
    }

    // MARK: - Numbers

    private var statsStrip: some View {
        StatsStrip(cells: [
            StatCell(value: "\(calculateStreak())", unit: nil, label: "Días seguidos",
                     detail: String(format: NSLocalizedString("Mejor %lld", comment: ""), friendsManager.myStreak?.longestStreak ?? 0)),
            StatCell(value: "\(calculateWorkouts())", unit: nil, label: "Entrenos", detail: nil),
            StatCell(value: "\(calculateDaysActive())", unit: nil, label: "Días en la app", detail: nil),
        ])
    }

    // MARK: - Account rows

    private var accountSlab: some View {
        VStack(spacing: 0) {
            PlanActionRow(glyph: "person", title: "Editar perfil") { showingEditProfile = true }
            PlanActionRow(glyph: "figure.arms.open", title: "Medidas corporales",
                          locked: !storeKitManager.hasActiveSubscription) {
                if storeKitManager.hasActiveSubscription { showingBodyMeasurements = true } else { showingSubscription = true }
            }
            PlanActionRow(glyph: "creditcard", title: "Suscripción") { showingSubscription = true }
            if storeKitManager.hasActiveSubscription {
                PlanActionRow(glyph: "arrow.up.forward.square", title: "Gestionar pagos") {
                    Task { await storeKitManager.openSubscriptionManagement() }
                }
            }
            PlanActionRow(glyph: "square.and.arrow.up", title: "Exportar mis datos", showsSeparator: false) { exportUserData() }
        }
        .slab()
    }

    // MARK: - Friends

    private var friendsSlab: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Amigos")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)
                Spacer()
                if !friendsManager.friends.isEmpty {
                    Text("Días seguidos")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)

            if friendsManager.isLoading && friendsManager.friends.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            } else if friendsManager.friends.isEmpty {
                Text("Añade amigos para ver sus entrenos y competir por la racha.")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.sm)
            } else {
                let friends = friendsManager.friends
                ForEach(Array(friends.enumerated()), id: \.element.id) { i, friend in
                    Button { selectedFriend = friend } label: {
                        SlabRow(showsSeparator: i < friends.count - 1, minHeight: 52) {
                            HStack(spacing: Spacing.sm + 2) {
                                ProfileAvatar(name: friend.name, url: friend.profileImageURL, size: 28)
                                Text(friend.name)
                                    .font(.system(.subheadline, weight: .regular))
                                    .foregroundColor(BulkUpColors.textPrimary)
                                    .lineLimit(1)
                                Spacer(minLength: Spacing.sm)
                                Text("\(friend.currentStreak)")
                                    .font(BulkUpFont.numeric(.subheadline, weight: .semibold))
                                    .foregroundColor(BulkUpColors.textPrimary)
                                Image(systemName: "chevron.right")
                                    .font(.system(.caption, weight: .semibold))
                                    .foregroundColor(BulkUpColors.textTertiary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(Text(String(format: NSLocalizedString("%lld días seguidos", comment: ""), friend.currentStreak)))
                    .accessibilityHint("Abre su perfil")
                }
            }

            HStack(spacing: Spacing.md) {
                Button { showingMyCode = true } label: {
                    Text("Mi código")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(BulkUpColors.accentText)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button { showingAddFriend = true } label: {
                    Text("Añadir amigo")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(BulkUpColors.accentText)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .overlay(alignment: .top) {
                Rectangle().fill(BulkUpColors.line).frame(height: 1).padding(.leading, Spacing.md)
            }
        }
        .slab()
    }

    // MARK: - Quick settings

    private var quickSettingsSlab: some View {
        VStack(spacing: 0) {
            SlabRow(minHeight: 52) {
                Toggle(isOn: $hapticFeedback) {
                    Label("Vibración háptica", systemImage: "iphone.radiowaves.left.and.right")
                        .labelStyle(ProfileLabelStyle())
                }
                .tint(BulkUpColors.accent)
            }
            SlabRow(showsSeparator: false, minHeight: 52) {
                Toggle(isOn: Binding(
                    get: { notificationsEnabled },
                    set: { newValue in
                        notificationsEnabled = newValue
                        if newValue { requestNotificationPermission() }
                    }
                )) {
                    Label("Notificaciones", systemImage: "bell")
                        .labelStyle(ProfileLabelStyle())
                }
                .tint(BulkUpColors.accent)
            }
        }
        .slab()
    }

    // MARK: - Session / account

    private var accountActions: some View {
        VStack(spacing: Spacing.sm) {
            Button { showingLogoutAlert = true } label: {
                Text("Cerrar sesión")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .pressable()

            Button { showingDeleteAccountAlert = true } label: {
                Text("Eliminar cuenta")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text("BulkUp · v\(Bundle.main.appVersion)")
                .font(BulkUpFont.numeric(.caption2, weight: .medium))
                .foregroundColor(BulkUpColors.textTertiary)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Helper Functions

    private func deleteAccount() async {
        do {
            try await authManager.deleteAccount()
            // On success `isAuthenticated` becomes false and the app falls back to the login screen.
        } catch {
            deleteAccountErrorMessage = error.localizedDescription
            showingDeleteAccountError = true
        }
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

/// Glyph in secondary at the row's 28pt column, title in subheadline semibold.
struct ProfileLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Spacing.md) {
            configuration.icon
                .font(.system(.body, weight: .medium))
                .foregroundColor(BulkUpColors.textSecondary)
                .frame(width: 28)
            configuration.title
                .font(.system(.headline, weight: .semibold))
                .foregroundColor(BulkUpColors.textPrimary)
        }
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
