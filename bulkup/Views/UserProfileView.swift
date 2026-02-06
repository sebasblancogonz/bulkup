//
//  UserProfileView.swift
//  bulkup
//
//  Created by sebastian.blanco on 11/9/25.
//

import PhotosUI
import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var storeKitManager = StoreKitManager.shared

    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingSubscription = false
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?

    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("notifications") private var notificationsEnabled = true
    @AppStorage("darkMode") private var darkModeEnabled = false

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
                action: { /* Navigate to payment history */  }
            )

            MenuRow(
                title: "Exportar Datos",
                icon: "square.and.arrow.up",
                color: .orange,
                action: { /* Export data */  }
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
                    isOn: $notificationsEnabled
                )

                SettingRow(
                    title: "Modo oscuro",
                    icon: "moon",
                    isOn: $darkModeEnabled
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

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
