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

    var body: some View {
        NavigationView {
            List {
                // MARK: - Notificaciones
                Section("Notificaciones") {
                    SettingsToggle(
                        icon: "dumbbell.fill",
                        iconColor: .blue,
                        title: "Recordatorios de Entrenamiento",
                        subtitle: "Te recordamos tus sesiones programadas",
                        isOn: $workoutReminders,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsToggle(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .green,
                        title: "Recordatorios de Progreso",
                        subtitle: "Actualiza tus medidas y peso",
                        isOn: $progressReminders,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsToggle(
                        icon: "calendar.badge.clock",
                        iconColor: .orange,
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
                        iconColor: .purple,
                        title: "Efectos de Sonido",
                        subtitle: "Sonidos al completar ejercicios",
                        isOn: $soundEffects,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsToggle(
                        icon: "iphone.radiowaves.left.and.right",
                        iconColor: .pink,
                        title: "Vibración Háptica",
                        subtitle: "Retroalimentación táctil",
                        isOn: $hapticFeedback,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsToggle(
                        icon: "timer",
                        iconColor: .red,
                        title: "Sonido de Descanso",
                        subtitle: "Alerta al finalizar tiempo de descanso",
                        isOn: $restTimerSound,
                        hapticFeedback: $hapticFeedback
                    )
                }

                // MARK: - Personalización
                Section("Personalización") {
                    SettingsPicker(
                        icon: "ruler.fill",
                        iconColor: .indigo,
                        title: "Sistema de Unidades",
                        selection: $units,
                        options: [
                            ("metric", "Métrico (kg, cm)"),
                            ("imperial", "Imperial (lbs, ft)"),
                        ]
                    )

                    SettingsPicker(
                        icon: "calendar",
                        iconColor: .teal,
                        title: "Inicio de Semana",
                        selection: $weekStart,
                        options: [
                            ("monday", "Lunes"),
                            ("sunday", "Domingo"),
                        ]
                    )

                    SettingsPicker(
                        icon: "paintpalette.fill",
                        iconColor: .cyan,
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
                        iconColor: .yellow,
                        title: "Mantener Pantalla Activa",
                        subtitle: "Durante los entrenamientos",
                        isOn: $keepScreenOn,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsRow(
                        icon: "stopwatch.fill",
                        iconColor: .orange,
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
                        iconColor: .blue,
                        title: "Respaldo Automático",
                        subtitle: "Sincronizar con iCloud",
                        isOn: $autoBackup,
                        hapticFeedback: $hapticFeedback
                    )

                    SettingsRow(
                        icon: "square.and.arrow.up.fill",
                        iconColor: .green,
                        title: "Exportar Datos",
                        subtitle: "Descargar tu información"
                    ) {
                        showingDataExport = true
                    }

                    SettingsRow(
                        icon: "lock.doc.fill",
                        iconColor: .gray,
                        title: "Política de Privacidad",
                        subtitle: "Cómo manejamos tus datos"
                    ) {
                        // Abrir política de privacidad
                        if let url = URL(string: "https://bulkup.app/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                // MARK: - Soporte
                Section("Soporte") {
                    SettingsRow(
                        icon: "questionmark.circle.fill",
                        iconColor: .blue,
                        title: "Centro de Ayuda",
                        subtitle: "Preguntas frecuentes y tutoriales"
                    ) {
                        // Navegar a ayuda
                    }

                    SettingsRow(
                        icon: "envelope.fill",
                        iconColor: .green,
                        title: "Contactar Soporte",
                        subtitle: "Enviar feedback o reportar problemas"
                    ) {
                        // Abrir mail o formulario de contacto
                        let email = "support@bulkup.app"
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    }

                    SettingsRow(
                        icon: "star.fill",
                        iconColor: .yellow,
                        title: "Calificar App",
                        subtitle: "Déjanos tu opinión en App Store"
                    ) {
                        // Abrir App Store para calificar
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
                        iconColor: .blue,
                        title: "Acerca de BulkUp",
                        subtitle: "Versión 1.0.0"
                    ) {
                        showingAbout = true
                    }

                    SettingsRow(
                        icon: "doc.text.fill",
                        iconColor: .gray,
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
                        iconColor: .red,
                        title: "Eliminar Cuenta",
                        subtitle: "Acción permanente e irreversible"
                    ) {
                        showingDeleteAccount = true
                    }
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAbout) {
        }
        .sheet(isPresented: $showingDataExport) {
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
    }

    private func applyTheme(_ theme: String) {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first
                as? UIWindowScene,
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
                Text(title)
                    .font(.body)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
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

            Text(title)

            Spacer()

            Picker(title, selection: $selection) {
                ForEach(options, id: \.0) { option in
                    Text(option.1).tag(option.0)
                }
            }
            .pickerStyle(.menu)
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
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
}
