//
//  SettingsView.swift
//  bulkup
//
//  Created by sebastian.blanco on 27/8/25.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    // Estados para configuraciones
    @AppStorage("workoutReminders") private var workoutReminders = true
    @AppStorage("progressReminders") private var progressReminders = true
    @AppStorage("weeklyReports") private var weeklyReports = true
    @AppStorage("soundEffects") private var soundEffects = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("restTimerSound") private var restTimerSound = true
    @AppStorage("units") private var units = "metric"  // metric/imperial
    @AppStorage("weekStart") private var weekStart = "monday"  // monday/sunday
    @AppStorage("theme") private var theme = "system"  // system/light/dark
    @AppStorage("autoBackup") private var autoBackup = true
    @AppStorage("keepScreenOn") private var keepScreenOn = false

    @State private var showingAbout = false
    @State private var showingDataExport = false
    @State private var showingDeleteAccount = false
    @State private var exportFileURL: URL?

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Notificaciones
                Section("Notificaciones") {
                    SettingsToggle(
                        icon: "dumbbell.fill",
                        iconColor: BulkUpColors.training,
                        title: "Recordatorios de Entrenamiento",
                        subtitle: "Te recordamos tus sesiones programadas",
                        isOn: $workoutReminders,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsToggle(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: BulkUpColors.success,
                        title: "Recordatorios de Progreso",
                        subtitle: "Actualiza tus medidas y peso",
                        isOn: $progressReminders,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsToggle(
                        icon: "calendar.badge.clock",
                        iconColor: BulkUpColors.accent,
                        title: "Reportes Semanales",
                        subtitle: "Resumen de tu semana de entrenamiento",
                        isOn: $weeklyReports,
                        hapticFeedback: $hapticFeedback
                    )
                }

                // MARK: - Audio y Retroalimentación
                Section("Audio y Retroalimentación") {
                    SettingsToggle(
                        icon: "speaker.wave.2.fill",
                        iconColor: BulkUpColors.secondary,
                        title: "Efectos de Sonido",
                        subtitle: "Sonidos al completar ejercicios",
                        isOn: $soundEffects,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsToggle(
                        icon: "iphone.radiowaves.left.and.right",
                        iconColor: BulkUpColors.accent,
                        title: "Vibración Háptica",
                        subtitle: "Retroalimentación táctil",
                        isOn: $hapticFeedback,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsToggle(
                        icon: "timer",
                        iconColor: BulkUpColors.error,
                        title: "Sonido de Descanso",
                        subtitle: "Alerta al finalizar tiempo de descanso",
                        isOn: $restTimerSound,
                        hapticFeedback: $hapticFeedback
                    )
                }

                // MARK: - Personalización
                Section("Personalización") {
                    SettingsPicker(
                        icon: "globe",
                        iconColor: BulkUpColors.accent,
                        title: "Idioma / Language",
                        selection: Binding(
                            get: { languageManager.language.rawValue },
                            set: { languageManager.language = AppLanguage(rawValue: $0) ?? .system }
                        ),
                        options: [
                            ("system", "Sistema / System"),
                            ("es", "Español"),
                            ("en", "English"),
                        ]
                    )

                    SettingsPicker(
                        icon: "ruler.fill",
                        iconColor: BulkUpColors.accent,
                        title: "Sistema de Unidades",
                        selection: $units,
                        options: [
                            ("metric", "Métrico (kg, cm)"),
                            ("imperial", "Imperial (lbs, ft)"),
                        ]
                    )

                    SettingsPicker(
                        icon: "calendar",
                        iconColor: BulkUpColors.accent,
                        title: "Inicio de Semana",
                        selection: $weekStart,
                        options: [
                            ("monday", "Lunes"),
                            ("sunday", "Domingo"),
                        ]
                    )

                    SettingsPicker(
                        icon: "paintpalette.fill",
                        iconColor: BulkUpColors.accent,
                        title: "Tema de Apariencia",
                        selection: $theme,
                        options: [
                            ("system", "Sistema"),
                            ("light", "Claro"),
                            ("dark", "Oscuro"),
                        ]
                    )
                }

                // MARK: - Entrenamiento
                Section("Entrenamiento") {
                    SettingsToggle(
                        icon: "lock.fill",
                        iconColor: BulkUpColors.accent,
                        title: "Mantener Pantalla Activa",
                        subtitle: "Durante los entrenamientos",
                        isOn: $keepScreenOn,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsRow(
                        icon: "stopwatch.fill",
                        iconColor: BulkUpColors.accent,
                        title: "Tiempos de Descanso",
                        subtitle: "Configurar por defecto"
                    ) {
                        // Navegar a configuración de tiempos
                    }
                }

                // MARK: - Datos y Privacidad
                Section("Datos y Privacidad") {
                    SettingsToggle(
                        icon: "icloud.fill",
                        iconColor: BulkUpColors.training,
                        title: "Respaldo Automático",
                        subtitle: "Sincronizar con iCloud",
                        isOn: $autoBackup,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsRow(
                        icon: "square.and.arrow.up.fill",
                        iconColor: BulkUpColors.success,
                        title: "Exportar Datos",
                        subtitle: "Descargar tu información"
                    ) {
                        exportData()
                    }

                    SettingsRow(
                        icon: "lock.doc.fill",
                        iconColor: BulkUpColors.textSecondary,
                        title: "Política de Privacidad",
                        subtitle: "Cómo manejamos tus datos"
                    ) {
                        if let url = URL(string: "https://bulkup.app/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                // MARK: - Soporte
                Section("Soporte") {
                    SettingsRow(
                        icon: "questionmark.circle.fill",
                        iconColor: BulkUpColors.accent,
                        title: "Centro de Ayuda",
                        subtitle: "Preguntas frecuentes y tutoriales"
                    ) {
                        // Navegar a ayuda
                    }

                    SettingsRow(
                        icon: "envelope.fill",
                        iconColor: BulkUpColors.accent,
                        title: "Contactar Soporte",
                        subtitle: "Enviar feedback o reportar problemas"
                    ) {
                        let email = "support@bulkup.app"
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    }

                    SettingsRow(
                        icon: "star.fill",
                        iconColor: BulkUpColors.accent,
                        title: "Calificar App",
                        subtitle: "Déjanos tu opinión en App Store"
                    ) {
                        if let url = URL(
                            string:
                                "https://apps.apple.com/app/bulkup/id123456789?action=write-review"
                        ) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                // MARK: - Información
                Section("Información") {
                    SettingsRow(
                        icon: "info.circle.fill",
                        iconColor: BulkUpColors.accent,
                        title: "Acerca de BulkUp",
                        subtitle: "Versión 1.0.0"
                    ) {
                        showingAbout = true
                    }

                    SettingsRow(
                        icon: "doc.text.fill",
                        iconColor: BulkUpColors.textSecondary,
                        title: "Términos de Servicio"
                    ) {
                        if let url = URL(string: "https://bulkup.app/terms") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                // MARK: - Cuenta (Peligroso)
                Section("Gestión de Cuenta") {
                    SettingsRow(
                        icon: "trash.fill",
                        iconColor: BulkUpColors.error,
                        title: "Eliminar Cuenta",
                        subtitle: "Acción permanente e irreversible"
                    ) {
                        showingDeleteAccount = true
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(BulkUpColors.accent)
                }
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingDataExport) {
            if let url = exportFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Eliminar Cuenta", isPresented: $showingDeleteAccount) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                // Lógica para eliminar cuenta
            }
        } message: {
            Text(
                "Esta acción eliminará permanentemente tu cuenta y todos tus datos. No se puede deshacer."
            )
        }
        .onChange(of: theme) { _, newValue in
            applyTheme(newValue)
        }
        .onChange(of: keepScreenOn) { _, newValue in
            UIApplication.shared.isIdleTimerDisabled = newValue
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            applyTheme(theme)
        }
    }

    private func exportData() {
        let dietManager = DietManager.shared
        let trainingManager = TrainingManager.shared
        let measurementsManager = BodyMeasurementsManager.shared
        var exportData: [String: Any] = [:]
        let dateFormatter = ISO8601DateFormatter()

        if let user = authManager.user {
            exportData["perfil"] = [
                "nombre": user.name,
                "email": user.email,
            ]
        }

        if !dietManager.dietData.isEmpty {
            exportData["dieta"] = dietManager.dietData.map { day -> [String: Any] in
                var d: [String: Any] = ["dia": day.day]
                d["comidas"] = day.meals.map { meal -> [String: Any] in
                    var m: [String: Any] = ["tipo": meal.type, "hora": meal.time]
                    m["opciones"] = meal.options.map {
                        ["descripcion": $0.optionDescription, "ingredientes": $0.ingredients]
                    }
                    return m
                }
                return d
            }
        }

        if !trainingManager.trainingData.isEmpty {
            exportData["entrenamiento"] = trainingManager.trainingData.map { day -> [String: Any] in
                var d: [String: Any] = ["dia": day.day]
                if let name = day.workoutName { d["nombreEntrenamiento"] = name }
                d["ejercicios"] = day.exercises.map {
                    [
                        "nombre": $0.name, "series": $0.sets,
                        "repeticiones": $0.reps, "descanso": $0.restSeconds,
                    ] as [String: Any]
                }
                return d
            }
        }

        if let m = measurementsManager.currentMeasurements {
            exportData["medidas"] = [
                "peso": m.peso, "altura": m.altura,
                "cintura": m.cintura, "cuello": m.cuello,
            ]
        }

        exportData["fechaExportacion"] = dateFormatter.string(from: Date())

        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                "BulkUp_Export.json")
            try jsonData.write(to: tempURL)
            exportFileURL = tempURL
            showingDataExport = true
        } catch {
            print("Error exporting data: \(error)")
        }
    }

    private func applyTheme(_ value: String) {
        let style: UIUserInterfaceStyle = value == "light" ? .light : value == "dark" ? .dark : .unspecified
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
}

// MARK: - Componentes Auxiliares
struct SettingsToggle: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    @Binding var hapticFeedback: Bool

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>,
        hapticFeedback: Binding<Bool>
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self._hapticFeedback = hapticFeedback
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(title))
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)

                if let subtitle = subtitle {
                    Text(LocalizedStringKey(subtitle))
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(BulkUpColors.accent)
        }
        .onChange(of: isOn) {
            HapticManager.shared.trigger(.selection, enabled: hapticFeedback)
        }
    }
}

struct SettingsPicker: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var selection: String
    let options: [(String, String)]

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            Text(LocalizedStringKey(title))
                .foregroundColor(BulkUpColors.textPrimary)

            Spacer()

            Picker(title, selection: $selection) {
                ForEach(options, id: \.0) { option in
                    Text(LocalizedStringKey(option.1)).tag(option.0)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(BulkUpColors.accent)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: () -> Void

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(LocalizedStringKey(subtitle))
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(BulkUpColors.textSecondary)
                    .font(BulkUpFont.caption())
            }
            .contentShape(Rectangle())
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(BulkUpColors.accent)

                Text("BulkUp")
                    .font(BulkUpFont.screenTitle())
                    .fontWeight(.bold)
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("Versión \(Bundle.main.appVersion)")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)

                Text("Tu compañero de entrenamiento y nutrición.")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Text("© 2025 BulkUp")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .padding(.bottom)
            }
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationTitle("Acerca de")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(BulkUpColors.accent)
                }
            }
        }
    }
}
