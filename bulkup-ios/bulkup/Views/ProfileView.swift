//
//  ProfileView.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//

import SwiftData
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var measurementsManager = BodyMeasurementsManager.shared
    @ObservedObject private var mealTrackingManager = MealTrackingManager.shared
    @State private var showingBodyMeasurements = false
    @State private var showingEditProfile = false
    @State private var showSettings = false
    @State private var projection: NutritionProjection?

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                // Avatar grande
                VStack(spacing: Spacing.lg) {
                    if let urlString = authManager.user?.safeProfileImageURL,
                       let url = URL(string: urlString) {

                        CachedAsyncImage(url: url) { image, colors in
                            ZStack {
                                // Sombra/blur con colores de la imagen
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .blur(radius: 25)
                                    .opacity(0.4)
                                    .offset(y: 8)

                                // Imagen principal
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(BulkUpColors.accent, lineWidth: 2.5)
                                    )
                            }
                        } placeholder: {
                            // Fallback con iniciales
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [BulkUpColors.accent.opacity(0.6), BulkUpColors.accent.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 25)
                                    .opacity(0.4)
                                    .offset(y: 8)

                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [BulkUpColors.accent, BulkUpColors.accent.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text(
                                            authManager.user?.name.prefix(2).uppercased() ?? "US"
                                        )
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                    )
                            }
                        }

                    } else {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [BulkUpColors.accent.opacity(0.6), BulkUpColors.accent.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .blur(radius: 25)
                                .opacity(0.4)
                                .offset(y: 8)

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [BulkUpColors.accent, BulkUpColors.accent.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(
                                        authManager.user?.name.prefix(2).uppercased() ?? "US"
                                    )
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                                )
                        }
                    }

                    VStack(spacing: Spacing.xs) {
                        Text(authManager.user?.name ?? "Usuario")
                            .font(BulkUpFont.sectionHeader())
                            .foregroundColor(BulkUpColors.textPrimary)

                        Text(authManager.user?.email ?? "")
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                }

                // Opciones
                VStack(spacing: Spacing.md) {
                    ProfileMenuItem(
                        icon: "person.crop.circle",
                        title: "Editar Perfil",
                        action: {
                            showingEditProfile = true
                        }
                    )

                    ProfileMenuItem(
                        icon: "figure.arms.open",
                        title: "Medidas Corporales",
                        subtitle: "Seguimiento y composición",
                        action: {
                            showingBodyMeasurements = true
                        }
                    )

                    ProfileMenuItem(
                        icon: "bell",
                        title: "Notificaciones",
                        action: {}
                    )

                    ProfileMenuItem(
                        icon: "gear",
                        title: "Configuración",
                        action: {
                            showSettings = true
                        }
                    )
                }
                .padding()

                // Nutrition Summary
                NutritionSummaryCard(
                    measurements: measurementsManager.currentMeasurements,
                    composition: measurementsManager.bodyComposition,
                    complianceStats: mealTrackingManager.complianceStats
                )
                .padding(.horizontal)

                // Projections
                ProjectionsCard(
                    projection: projection,
                    reviewDate: authManager.user?.nextReviewDate
                )
                .padding(.horizontal)

                Spacer()

                // Cerrar sesión
                Button(action: {
                    authManager.logout()
                    dismiss()
                }) {
                    Text("Cerrar Sesión")
                        .fontWeight(.semibold)
                        .foregroundColor(BulkUpColors.error)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(BulkUpColors.error.opacity(0.1))
                        .cornerRadius(CornerRadius.medium)
                }
                .padding()
            }
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(BulkUpColors.accent)
                }
            }
            .onAppear {
                loadProfileMetrics()
            }
        }
        .sheet(isPresented: $showingBodyMeasurements) {
            BodyMeasurementsView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(authManager)
        }
    }

    private func loadProfileMetrics() {
        guard let userId = authManager.user?.id else { return }
        Task {
            async let loadMeasurements: () = measurementsManager.loadLatestMeasurements(userId: userId)
            async let loadStats: () = mealTrackingManager.loadComplianceStats(userId: userId)
            _ = await (loadMeasurements, loadStats)

            if let measurementId = measurementsManager.currentMeasurements?.id {
                _ = await measurementsManager.calculateBodyComposition(measurementId: measurementId)
            }

            computeProjection()
        }
    }

    private func computeProjection() {
        guard let composition = measurementsManager.bodyComposition,
              let measurements = measurementsManager.currentMeasurements,
              let reviewDate = authManager.user?.nextReviewDate else {
            projection = nil
            return
        }

        let daysToReview = Calendar.current.dateComponents([.day], from: Date(), to: reviewDate).day ?? 0
        guard daysToReview > 0 else {
            projection = nil
            return
        }

        let complianceRate = mealTrackingManager.complianceStats?.complianceRate ?? 0.0

        projection = ProjectionCalculator.calculate(
            currentWeight: measurements.peso,
            currentBodyFatPercentage: composition.bodyFatPercentage,
            currentLeanMass: composition.leanMass,
            complianceRate: complianceRate,
            daysToReview: daysToReview,
            sex: measurements.sexo
        )
    }
}
