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
    
    var body: some View {
        NavigationView {
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
                            .foregroundColor(.red)
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
        VStack(spacing: 8) {
            Text(measurement.fecha.formatted(date: .complete, time: .omitted))
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Hace \(daysAgo) días")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Measurements Section
    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medidas Principales")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DetailMetricCard(
                    title: "Peso",
                    value: String(format: "%.1f", measurement.peso),
                    unit: "kg",
                    icon: "scalemass",
                    color: .blue
                )
                
                DetailMetricCard(
                    title: "Altura",
                    value: String(format: "%.0f", measurement.altura),
                    unit: "cm",
                    icon: "ruler",
                    color: .purple
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
                    color: .orange
                )
                
                DetailMetricCard(
                    title: "Cintura",
                    value: String(format: "%.1f", measurement.cintura),
                    unit: "cm",
                    icon: "circle.dashed",
                    color: .green
                )
                
                DetailMetricCard(
                    title: "Cuello",
                    value: String(format: "%.1f", measurement.cuello),
                    unit: "cm",
                    icon: "circle",
                    color: .teal
                )
            }
        }
    }
    
    // MARK: - Comparison Section
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cambios desde la medición anterior")
                .font(.headline)
                .fontWeight(.bold)
            
            if let previous = previousMeasurement {
                VStack(spacing: 12) {
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
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Body Composition Section
    private var bodyCompositionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Composición Corporal")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if isCalculatingComposition {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let composition = bodyComposition {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    CompositionCard(
                        title: "% Grasa",
                        value: String(format: "%.1f%%", composition.porcentajeGrasa),
                        color: .orange
                    )
                    
                    CompositionCard(
                        title: "Masa Muscular",
                        value: String(format: "%.1f kg", composition.masaMuscular),
                        color: .green
                    )
                    
                    CompositionCard(
                        title: "Masa Magra",
                        value: String(format: "%.1f kg", composition.masaMagra),
                        color: .blue
                    )
                    
                    CompositionCard(
                        title: "Agua Corporal",
                        value: String(format: "%.1f kg", composition.aguaCorporal),
                        color: .cyan
                    )
                }
            } else if !isCalculatingComposition {
                Button("Calcular Composición Corporal") {
                    Task {
                        await calculateComposition()
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
    
    // MARK: - Additional Measurements Section
    private var additionalMeasurementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medidas Adicionales")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let cadera = measurement.cadera {
                    DetailMetricCard(
                        title: "Cadera",
                        value: String(format: "%.1f", cadera),
                        unit: "cm",
                        icon: "circle.dotted",
                        color: .indigo
                    )
                }
                
                if let brazo = measurement.brazo {
                    DetailMetricCard(
                        title: "Brazo",
                        value: String(format: "%.1f", brazo),
                        unit: "cm",
                        icon: "figure.arms.open",
                        color: .pink
                    )
                }
                
                if let muslo = measurement.muslo {
                    DetailMetricCard(
                        title: "Muslo",
                        value: String(format: "%.1f", muslo),
                        unit: "cm",
                        icon: "figure.walk",
                        color: .brown
                    )
                }
                
                if let pantorrilla = measurement.pantorrilla {
                    DetailMetricCard(
                        title: "Pantorrilla",
                        value: String(format: "%.1f", pantorrilla),
                        unit: "cm",
                        icon: "figure.run",
                        color: .mint
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
        case ..<18.5: return .blue
        case 18.5..<25: return .green
        case 25..<30: return .orange
        default: return .red
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
    
    private func deleteMeasurement() {
        guard let measurementId = measurement.id,
              let userId = authManager.user?.id else { return }
        
        Task {
            await measurementsManager.deleteMeasurement(measurementId: measurementId, userId: userId)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
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
        if difference == 0 { return .secondary }
        let isPositive = difference > 0
        if inverseColors {
            return isPositive ? .green : .red
        } else {
            return isPositive ? .red : .green
        }
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(String(format: format + " %@", current, unit))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if difference != 0 {
                        Image(systemName: difference > 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                            .foregroundColor(changeColor)
                    }
                }
                
                if abs(difference) > 0.01 {
                    Text(String(format: "%+.1f %@ (%.1f%%)", difference, unit, percentChange))
                        .font(.caption)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.green.opacity(0.1))
            .foregroundColor(.green)
            .cornerRadius(12)
            .fontWeight(.medium)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
