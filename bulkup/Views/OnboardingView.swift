//
//  OnboardingView.swift
//  bulkup
//
//  Created by sebastian.blanco on 14/4/26.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userGoal") private var userGoal = ""

    @State private var currentStep = 0
    @State private var selectedGoal: UserGoal?

    // Measurements fields
    @State private var weightText = ""
    @State private var heightText = ""
    @State private var ageText = ""
    @State private var isSavingMeasurements = false

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            if currentStep > 0 {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }

            // Content
            TabView(selection: $currentStep) {
                welcomeScreen
                    .tag(0)
                goalScreen
                    .tag(1)
                measurementsScreen
                    .tag(2)
                firstPlanScreen
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
        .background(
            BulkUpColors.background
                .ignoresSafeArea()
        )
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? BulkUpColors.accent : BulkUpColors.surfaceElevated)
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Screen 1: Welcome

    private var welcomeScreen: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            Image("BulkUp")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)

            VStack(spacing: Spacing.sm) {
                Text("Bienvenido a BulkUp")
                    .font(BulkUpFont.screenTitle())
                    .fontWeight(.bold)
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("Come, entrena, crece, repite")
                    .font(BulkUpFont.sectionHeader())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 20) {
                valuePropRow(
                    icon: "dumbbell.fill",
                    color: BulkUpColors.training,
                    text: String(localized: "Planifica tu entrenamiento")
                )
                valuePropRow(
                    icon: "fork.knife",
                    color: BulkUpColors.diet,
                    text: String(localized: "Controla tu alimentacion")
                )
                valuePropRow(
                    icon: "chart.line.uptrend.xyaxis",
                    color: BulkUpColors.accent,
                    text: String(localized: "Mide tu progreso")
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            primaryButton(title: String(localized: "Comenzar")) {
                withAnimation(.easeInOut) {
                    currentStep = 1
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Screen 2: Goal Selection

    private var goalScreen: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
                .frame(height: 40)

            VStack(spacing: Spacing.sm) {
                Text("Cual es tu objetivo?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("Esto nos ayuda a personalizar tu experiencia")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            VStack(spacing: Spacing.lg) {
                goalCard(
                    goal: .gainMuscle,
                    icon: "figure.strengthtraining.traditional",
                    title: String(localized: "Ganar masa muscular"),
                    subtitle: String(localized: "Aumentar volumen y fuerza")
                )
                goalCard(
                    goal: .loseFat,
                    icon: "flame.fill",
                    title: String(localized: "Perder grasa"),
                    subtitle: String(localized: "Definicion y perdida de peso")
                )
                goalCard(
                    goal: .maintain,
                    icon: "heart.circle.fill",
                    title: String(localized: "Mantener y mejorar"),
                    subtitle: String(localized: "Recomposicion corporal")
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            primaryButton(title: String(localized: "Continuar")) {
                if let goal = selectedGoal {
                    userGoal = goal.rawValue
                }
                withAnimation(.easeInOut) {
                    currentStep = 2
                }
            }
            .disabled(selectedGoal == nil)
            .opacity(selectedGoal == nil ? 0.5 : 1)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Screen 3: Basic Measurements

    private var measurementsScreen: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
                .frame(height: 40)

            VStack(spacing: Spacing.sm) {
                Text("Tus medidas basicas")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("Esto nos ayuda a calcular tus proyecciones")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            VStack(spacing: Spacing.lg) {
                measurementField(
                    placeholder: String(localized: "Peso"),
                    unit: String(localized: "kg"),
                    icon: "scalemass.fill",
                    text: $weightText
                )
                measurementField(
                    placeholder: String(localized: "Altura"),
                    unit: String(localized: "cm"),
                    icon: "ruler.fill",
                    text: $heightText
                )
                measurementField(
                    placeholder: String(localized: "Edad"),
                    unit: String(localized: "anos"),
                    icon: "calendar",
                    text: $ageText
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: Spacing.md) {
                primaryButton(title: String(localized: "Guardar y continuar")) {
                    Task {
                        await saveMeasurementsAndContinue()
                    }
                }
                .disabled(isSavingMeasurements || !measurementsAreValid)
                .opacity(measurementsAreValid ? 1 : 0.5)

                Button {
                    withAnimation(.easeInOut) {
                        currentStep = 3
                    }
                } label: {
                    Text("Omitir por ahora")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Screen 4: First Plan

    private var firstPlanScreen: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
                .frame(height: 40)

            VStack(spacing: Spacing.sm) {
                Text("Crea tu primer plan")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("Puedes subir una foto o PDF de tu plan y nuestra IA lo digitaliza al instante")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenH)
            }

            // AI sparkle
            HStack(spacing: Spacing.sm) {
                Image(systemName: "sparkles")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.accent)
                Text("Powered by AI")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.accent)
            }

            VStack(spacing: Spacing.lg) {
                planCard(
                    icon: "dumbbell.fill",
                    title: String(localized: "Subir plan de entrenamiento"),
                    subtitle: String(localized: "Nuestra IA convierte tu plan en un formato interactivo"),
                    color: BulkUpColors.training
                ) {
                    hasCompletedOnboarding = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(
                            name: .onboardingOpenTrainingUpload,
                            object: nil
                        )
                    }
                }

                planCard(
                    icon: "leaf.fill",
                    title: String(localized: "Subir plan de dieta"),
                    subtitle: String(localized: "Digitaliza tu dieta y lleva el seguimiento diario"),
                    color: BulkUpColors.diet
                ) {
                    hasCompletedOnboarding = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(
                            name: .onboardingOpenDietUpload,
                            object: nil
                        )
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                hasCompletedOnboarding = true
            } label: {
                Text("Explorar la app")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Components

    private func valuePropRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(BulkUpFont.body())
                    .foregroundColor(.white)
            }

            Text(LocalizedStringKey(text))
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)
        }
    }

    private func goalCard(goal: UserGoal, icon: String, title: String, subtitle: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedGoal = goal
            }
        } label: {
            HStack(spacing: Spacing.lg) {
                Image(systemName: icon)
                    .font(BulkUpFont.sectionHeader())
                    .foregroundColor(selectedGoal == goal ? .white : BulkUpColors.accent)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedGoal == goal ? BulkUpColors.accent : BulkUpColors.accent.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(title))
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)

                    Text(LocalizedStringKey(subtitle))
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                Spacer()

                if selectedGoal == goal {
                    Image(systemName: "checkmark.circle.fill")
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.accent)
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(BulkUpColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(selectedGoal == goal ? BulkUpColors.accent : Color.clear, lineWidth: 2)
            )
            .shadow(color: selectedGoal == goal ? BulkUpColors.accent.opacity(0.15) : .black.opacity(0.05), radius: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func measurementField(placeholder: String, unit: String, icon: String, text: Binding<String>) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(BulkUpColors.textTertiary)
                .frame(width: 20)

            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .foregroundColor(BulkUpColors.textPrimary)

            Text(unit)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .padding()
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.medium)
    }

    private func planCard(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.lg) {
                Image(systemName: icon)
                    .font(BulkUpFont.sectionHeader())
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.medium)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(LocalizedStringKey(title))
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)

                    Text(LocalizedStringKey(subtitle))
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(BulkUpColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if isSavingMeasurements {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Text(LocalizedStringKey(title))
                }
            }
            .primaryButtonStyle(color: BulkUpColors.accent)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Logic

    private var measurementsAreValid: Bool {
        guard let weight = Double(weightText), weight > 0, weight < 500 else { return false }
        guard let height = Double(heightText), height > 0, height < 300 else { return false }
        guard let age = Int(ageText), age > 0, age < 120 else { return false }
        return true
    }

    private func saveMeasurementsAndContinue() async {
        guard measurementsAreValid,
              let userId = authManager.user?.id,
              let weight = Double(weightText),
              let height = Double(heightText),
              let age = Int(ageText)
        else { return }

        isSavingMeasurements = true
        defer { isSavingMeasurements = false }

        let manager = BodyMeasurementsManager.shared
        await manager.saveMeasurements(
            userId: userId,
            weight: weight,
            height: height,
            age: age,
            sex: "male",
            waist: 0,
            neck: 0
        )

        withAnimation(.easeInOut) {
            currentStep = 3
        }
    }
}

// MARK: - User Goal Enum

enum UserGoal: String, CaseIterable {
    case gainMuscle = "gain_muscle"
    case loseFat = "lose_fat"
    case maintain = "maintain"
}
