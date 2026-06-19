//
//  AddMeasurementsView.swift
//  bulkup
//
//  Created by sebastian.blanco on 25/8/25.
//

import SwiftUI

struct AddMeasurementsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var measurementsManager: BodyMeasurementsManager
    @ObservedObject private var profileManager = ProfileManager.shared
    @Environment(\.dismiss) private var dismiss

    // Campos requeridos
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var age: String = ""
    @State private var sex: String = "H" // H = Hombre, M = Mujer
    @State private var waist: String = ""
    @State private var neck: String = ""

    // Campos opcionales
    @State private var hip: String = ""
    @State private var arm: String = ""
    @State private var thigh: String = ""
    @State private var calf: String = ""

    @State private var showingOptionalFields = false
    @State private var isLoading = false
    @State private var hasCalculatedAge = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "figure.arms.open")
                            .font(.system(size: 50))
                            .foregroundColor(BulkUpColors.accent)

                        Text("Nuevas Medidas")
                            .font(BulkUpFont.sectionHeader())
                            .foregroundColor(BulkUpColors.textPrimary)

                        Text("Registra tus medidas para calcular tu composición corporal")
                            .font(BulkUpFont.body())
                            .foregroundColor(BulkUpColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Campos requeridos
                    VStack(spacing: 20) {
                        Text("Información Básica")
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: Spacing.lg) {
                            HStack(spacing: Spacing.md) {
                                MeasurementField(
                                    title: "Peso",
                                    value: $weight,
                                    unit: "kg",
                                    icon: "scalemass"
                                )

                                MeasurementField(
                                    title: "Altura",
                                    value: $height,
                                    unit: "cm",
                                    icon: "ruler"
                                )
                            }

                            HStack(spacing: Spacing.md) {
                                MeasurementField(
                                    title: "Edad",
                                    value: $age,
                                    unit: "años",
                                    icon: "calendar"
                                )

                                // Selector de sexo
                                VStack(alignment: .leading, spacing: Spacing.sm) {
                                    Label("Sexo", systemImage: "person.2")
                                        .font(BulkUpFont.caption())
                                        .foregroundColor(BulkUpColors.textSecondary)

                                    Picker("Sexo", selection: $sex) {
                                        Text("Hombre").tag("H")
                                        Text("Mujer").tag("M")
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }

                            // Nota sobre edad calculada automáticamente
                            if hasCalculatedAge {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(BulkUpColors.training)
                                        .font(BulkUpFont.caption())

                                    Text("Edad calculada desde tu fecha de nacimiento. Puedes modificarla si es necesario.")
                                        .font(BulkUpFont.caption())
                                        .foregroundColor(BulkUpColors.textSecondary)
                                }
                                .padding(.horizontal)
                            }

                            HStack(spacing: Spacing.md) {
                                MeasurementField(
                                    title: "Cintura",
                                    value: $waist,
                                    unit: "cm",
                                    icon: "circle.dashed"
                                )

                                MeasurementField(
                                    title: "Cuello",
                                    value: $neck,
                                    unit: "cm",
                                    icon: "circle"
                                )
                            }
                        }
                    }

                    // Toggle para campos opcionales
                    Button {
                        withAnimation(.spring()) {
                            showingOptionalFields.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Medidas Adicionales")
                                .fontWeight(.medium)

                            Spacer()

                            Image(systemName: showingOptionalFields ? "chevron.up" : "chevron.down")
                                .font(BulkUpFont.caption())
                        }
                        .foregroundColor(BulkUpColors.accent)
                        .padding()
                        .background(BulkUpColors.accent.opacity(0.1))
                        .cornerRadius(CornerRadius.small)
                    }

                    // Campos opcionales
                    if showingOptionalFields {
                        VStack(spacing: Spacing.lg) {
                            HStack(spacing: Spacing.md) {
                                MeasurementField(
                                    title: "Cadera",
                                    value: $hip,
                                    unit: "cm",
                                    icon: "circle.dotted",
                                    isOptional: true
                                )

                                MeasurementField(
                                    title: "Brazo",
                                    value: $arm,
                                    unit: "cm",
                                    icon: "arm.wave",
                                    isOptional: true
                                )
                            }

                            HStack(spacing: Spacing.md) {
                                MeasurementField(
                                    title: "Muslo",
                                    value: $thigh,
                                    unit: "cm",
                                    icon: "figure.walk",
                                    isOptional: true
                                )

                                MeasurementField(
                                    title: "Pantorrilla",
                                    value: $calf,
                                    unit: "cm",
                                    icon: "figure.run",
                                    isOptional: true
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .slide))
                    }

                    // Botón de guardar
                    Button {
                        saveMeasurements()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }

                            Text(isLoading ? LocalizedStringKey("Guardando...") : LocalizedStringKey("Guardar Medidas"))
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: BulkUpColors.accent))
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)

                    Color.clear
                        .frame(height: 20)
                }
                .padding()
            }
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationTitle("Agregar Medidas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }.onAppear {
            calculateAgeFromProfile()
        }
    }

    // MARK: - Helpers
    private func parseDecimal(_ text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !weight.isEmpty &&
        !height.isEmpty &&
        !age.isEmpty &&
        !waist.isEmpty &&
        !neck.isEmpty &&
        parseDecimal(weight) != nil &&
        parseDecimal(height) != nil &&
        Int(age) != nil &&
        parseDecimal(waist) != nil &&
        parseDecimal(neck) != nil
    }

    // MARK: - Functions
    private func saveMeasurements() {
        guard let userId = authManager.user?.id,
              let weightValue = parseDecimal(weight),
              let heightValue = parseDecimal(height),
              let ageValue = Int(age),
              let waistValue = parseDecimal(waist),
              let neckValue = parseDecimal(neck) else {
            return
        }

        isLoading = true

        Task {
            await measurementsManager.saveMeasurements(
                userId: userId,
                weight: weightValue,
                height: heightValue,
                age: ageValue,
                sex: sex,
                waist: waistValue,
                neck: neckValue,
                hip: hip.isEmpty ? nil : parseDecimal(hip),
                arm: arm.isEmpty ? nil : parseDecimal(arm),
                thigh: thigh.isEmpty ? nil : parseDecimal(thigh),
                calf: calf.isEmpty ? nil : parseDecimal(calf)
            )

            isLoading = false

            if measurementsManager.errorMessage == nil {
                dismiss()
            }
        }
    }

    // MARK: - Calculate age from profile
    private func calculateAgeFromProfile() {
        if let dateOfBirth = authManager.user?.dateOfBirth {
            let calendar = Calendar.current
            let now = Date()
            let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)

            if let calculatedAge = ageComponents.year {
                age = String(calculatedAge)
                hasCalculatedAge = true
            }
        }
    }
}


// MARK: - Measurement Field Component
struct MeasurementField: View {
    let title: String
    @Binding var value: String
    let unit: String
    let icon: String
    var isOptional: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 4) {
                Label(LocalizedStringKey(title), systemImage: icon)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

                if isOptional {
                    Text("(opcional)")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }

            HStack {
                TextField("0", text: $value)
                    .keyboardType(.decimalPad)
                    .padding(Spacing.sm)
                    .background(BulkUpColors.surfaceElevated)
                    .cornerRadius(CornerRadius.small)

                Text(unit)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .frame(width: 30, alignment: .leading)
            }
        }
    }
}
