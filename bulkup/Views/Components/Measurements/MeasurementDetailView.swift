//
//  MeasurementDetailView.swift
//  bulkup
//
//  Created by sebastian.blanco on 25/8/25.
//

import SwiftUI

struct MeasurementDetailView: View {
    let measurement: BodyMeasurements
    let previousMeasurement: BodyMeasurements?

    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var measurementsManager: BodyMeasurementsManager
    @Environment(\.dismiss) private var dismiss

    @State private var bodyComposition: BodyComposition?
    @State private var isCalculatingComposition = false
    @State private var showingDeleteConfirmation = false
    @State private var showingBodyFatOverride = false
    @State private var bodyFatOverrideText = ""
    @State private var isSavingOverride = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Encabezado con fecha
                    headerView

                    // Medidas principales
                    measurementsSection

                    // Comparación con medición anterior
                    if previousMeasurement != nil {
                        comparisonSection
                    }

                    // Composición corporal
                    bodyCompositionSection

                    // Medidas adicionales
                    if hasAdditionalMeasurements {
                        additionalMeasurementsSection
                    }
                }
                .padding()
            }
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationTitle("Detalle de Medición")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(BulkUpColors.error)
                    }
                }
            }
        }
        .task {
            await calculateComposition()
        }
        .alert("Eliminar Medición", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                deleteMeasurement()
            }
        } message: {
            Text("Esta acción no se puede deshacer. ¿Estás seguro de que quieres eliminar esta medición?")
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: Spacing.sm) {
            Text(measurement.fecha.formatted(date: .complete, time: .omitted))
                .font(BulkUpFont.sectionHeader())
                .foregroundColor(BulkUpColors.textPrimary)

            Text("Hace \(daysAgo) días")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.medium)
    }

    // MARK: - Measurements Section
    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Medidas Principales")
                .sectionHeader()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.lg) {
                DetailMetricCard(
                    title: "Peso",
                    value: String(format: "%.1f", measurement.peso),
                    unit: "kg",
                    icon: "scalemass",
                    color: BulkUpColors.training
                )

                DetailMetricCard(
                    title: "Altura",
                    value: String(format: "%.0f", measurement.altura),
                    unit: "cm",
                    icon: "ruler",
                    color: BulkUpColors.secondary
                )

                DetailMetricCard(
                    title: "IMC",
                    value: String(format: "%.1f", imc),
                    unit: imcCategory,
                    icon: "person.fill",
                    color: imcColor
                )

                DetailMetricCard(
                    title: "Edad",
                    value: String(measurement.edad),
                    unit: "años",
                    icon: "calendar",
                    color: BulkUpColors.accent
                )

                DetailMetricCard(
                    title: "Cintura",
                    value: String(format: "%.1f", measurement.cintura),
                    unit: "cm",
                    icon: "circle.dashed",
                    color: BulkUpColors.success
                )

                DetailMetricCard(
                    title: "Cuello",
                    value: String(format: "%.1f", measurement.cuello),
                    unit: "cm",
                    icon: "circle",
                    color: BulkUpColors.accent
                )
            }
        }
    }

    // MARK: - Comparison Section
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Cambios desde la medición anterior")
                .sectionHeader()

            if let previous = previousMeasurement {
                VStack(spacing: Spacing.md) {
                    ComparisonRow(
                        title: "Peso",
                        current: measurement.peso,
                        previous: previous.peso,
                        unit: "kg",
                        format: "%.1f",
                        inverseColors: false
                    )

                    ComparisonRow(
                        title: "Cintura",
                        current: measurement.cintura,
                        previous: previous.cintura,
                        unit: "cm",
                        format: "%.1f",
                        inverseColors: false
                    )

                    ComparisonRow(
                        title: "Cuello",
                        current: measurement.cuello,
                        previous: previous.cuello,
                        unit: "cm",
                        format: "%.1f",
                        inverseColors: true
                    )

                    if let currentHip = measurement.cadera, let previousHip = previous.cadera {
                        ComparisonRow(
                            title: "Cadera",
                            current: currentHip,
                            previous: previousHip,
                            unit: "cm",
                            format: "%.1f",
                            inverseColors: false
                        )
                    }
                }
                .padding()
                .background(BulkUpColors.surfaceElevated)
                .cornerRadius(CornerRadius.medium)
            }
        }
    }

    // MARK: - Body Composition Section
    private var bodyCompositionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Text("Composición Corporal")
                    .sectionHeader()

                Spacer()

                if isCalculatingComposition || isSavingOverride {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if let composition = bodyComposition {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.md) {
                    // Body fat card with edit button
                    Button {
                        bodyFatOverrideText = String(format: "%.1f", composition.porcentajeGrasa)
                        showingBodyFatOverride = true
                    } label: {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text("% Grasa")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                                Spacer()
                                Image(systemName: "pencil")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.accent)
                            }

                            Text(String(format: "%.1f%%", composition.porcentajeGrasa))
                                .font(BulkUpFont.sectionHeader())
                                .foregroundColor(BulkUpColors.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(BulkUpColors.accent.opacity(0.1))
                        .cornerRadius(CornerRadius.medium)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    CompositionCard(
                        title: "Masa Muscular",
                        value: String(format: "%.1f kg", composition.masaMuscular),
                        color: BulkUpColors.success
                    )

                    CompositionCard(
                        title: "Masa Magra",
                        value: String(format: "%.1f kg", composition.masaMagra),
                        color: BulkUpColors.training
                    )

                    CompositionCard(
                        title: "Agua Corporal",
                        value: String(format: "%.1f kg", composition.aguaCorporal),
                        color: BulkUpColors.secondary
                    )
                }

                Text("Pulsa en % Grasa para corregirlo con tu dato real")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            } else if !isCalculatingComposition {
                Button("Calcular Composición Corporal") {
                    Task {
                        await calculateComposition()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .alert("Modificar % Grasa Corporal", isPresented: $showingBodyFatOverride) {
            TextField("% Grasa", text: $bodyFatOverrideText)
                .keyboardType(.decimalPad)
            Button("Cancelar", role: .cancel) { }
            Button("Guardar") {
                saveBodyFatOverride()
            }
        } message: {
            Text("Introduce el porcentaje de grasa proporcionado por tu nutricionista")
        }
    }

    // MARK: - Additional Measurements Section
    private var additionalMeasurementsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Medidas Adicionales")
                .sectionHeader()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.lg) {
                if let cadera = measurement.cadera {
                    DetailMetricCard(
                        title: "Cadera",
                        value: String(format: "%.1f", cadera),
                        unit: "cm",
                        icon: "circle.dotted",
                        color: BulkUpColors.secondary
                    )
                }

                if let brazo = measurement.brazo {
                    DetailMetricCard(
                        title: "Brazo",
                        value: String(format: "%.1f", brazo),
                        unit: "cm",
                        icon: "figure.arms.open",
                        color: BulkUpColors.secondary
                    )
                }

                if let muslo = measurement.muslo {
                    DetailMetricCard(
                        title: "Muslo",
                        value: String(format: "%.1f", muslo),
                        unit: "cm",
                        icon: "figure.walk",
                        color: BulkUpColors.accent
                    )
                }

                if let pantorrilla = measurement.pantorrilla {
                    DetailMetricCard(
                        title: "Pantorrilla",
                        value: String(format: "%.1f", pantorrilla),
                        unit: "cm",
                        icon: "figure.run",
                        color: BulkUpColors.success
                    )
                }
            }
        }
    }

    // MARK: - Helper Properties
    private var daysAgo: Int {
        Calendar.current.dateComponents([.day], from: measurement.fecha, to: Date()).day ?? 0
    }

    private var hasAdditionalMeasurements: Bool {
        measurement.cadera != nil || measurement.brazo != nil ||
        measurement.muslo != nil || measurement.pantorrilla != nil
    }

    private var imc: Double {
        measurement.peso / pow(measurement.altura / 100, 2)
    }

    private var imcCategory: String {
        switch imc {
        case ..<18.5: return "Bajo peso"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Sobrepeso"
        default: return "Obesidad"
        }
    }

    private var imcColor: Color {
        switch imc {
        case ..<18.5: return BulkUpColors.training
        case 18.5..<25: return BulkUpColors.success
        case 25..<30: return BulkUpColors.warning
        default: return BulkUpColors.error
        }
    }

    // MARK: - Functions
    private func calculateComposition() async {
        guard let measurementId = measurement.id, bodyComposition == nil else { return }
        isCalculatingComposition = true
        let result = await measurementsManager.calculateBodyComposition(measurementId: measurementId)
        bodyComposition = result
        isCalculatingComposition = false
    }

    private func saveBodyFatOverride() {
        let normalized = bodyFatOverrideText.replacingOccurrences(of: ",", with: ".")
        guard let measurementId = measurement.id,
              let percentage = Double(normalized),
              percentage > 0, percentage < 60 else { return }

        isSavingOverride = true
        Task {
            let result = await measurementsManager.overrideBodyFat(
                measurementId: measurementId,
                bodyFatPercentage: percentage
            )
            if let result {
                bodyComposition = result
            }
            isSavingOverride = false
        }
    }

    private func deleteMeasurement() {
        guard let measurementId = measurement.id,
              let userId = authManager.user?.id else { return }

        Task {
            _ = await measurementsManager.deleteMeasurement(measurementId: measurementId, userId: userId)
            dismiss()
        }
    }
}

// MARK: - Supporting Views
struct DetailMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(BulkUpFont.caption())
                    .foregroundColor(color)

                Text(title)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(BulkUpFont.sectionHeader())
                    .foregroundColor(BulkUpColors.textPrimary)

                Text(unit)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.medium)
    }
}

struct ComparisonRow: View {
    let title: String
    let current: Double
    let previous: Double
    let unit: String
    let format: String
    let inverseColors: Bool

    private var difference: Double { current - previous }
    private var percentChange: Double { ((current - previous) / previous) * 100 }

    private var changeColor: Color {
        if difference == 0 { return BulkUpColors.textSecondary }
        let isPositive = difference > 0
        if inverseColors {
            return isPositive ? BulkUpColors.success : BulkUpColors.error
        } else {
            return isPositive ? BulkUpColors.error : BulkUpColors.success
        }
    }

    var body: some View {
        HStack {
            Text(title)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(String(format: format + " %@", current, unit))
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textPrimary)

                    if difference != 0 {
                        Image(systemName: difference > 0 ? "arrow.up" : "arrow.down")
                            .font(BulkUpFont.caption())
                            .foregroundColor(changeColor)
                    }
                }

                if abs(difference) > 0.01 {
                    Text(String(format: "%+.1f %@ (%.1f%%)", difference, unit, percentChange))
                        .font(BulkUpFont.caption())
                        .foregroundColor(changeColor)
                }
            }
        }
    }
}

struct CompositionCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)

            Text(value)
                .font(BulkUpFont.sectionHeader())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.medium)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(BulkUpColors.accent.opacity(0.1))
            .foregroundColor(BulkUpColors.accent)
            .cornerRadius(CornerRadius.medium)
            .fontWeight(.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
