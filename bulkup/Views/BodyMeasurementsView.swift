//
//  BodyMeasurementsView.swift
//  bulkup
//
//  Created by sebastian.blanco on 25/8/25.
//

import SwiftUI
import Charts

struct BodyMeasurementsView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var measurementsManager = BodyMeasurementsManager.shared
    @State private var showingAddMeasurements = false
    @State private var selectedMeasurement: BodyMeasurements?
    @State private var hasAppeared = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if measurementsManager.isLoading && measurementsManager.measurementsHistory.isEmpty {
                    ProgressView("Cargando medidas...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if measurementsManager.measurementsHistory.isEmpty {
                    // Estado vacío
                    emptyStateView
                } else {
                    // Vista de resumen con gráfico
                    if let latest = measurementsManager.measurementsHistory.first {
                        summaryCard(for: latest)
                    }
                    
                    // Lista de registros
                    measurementsListView
                }
            }
            .padding()
        }
        .navigationTitle("Medidas Corporales")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddMeasurements = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
        }
        .sheet(isPresented: $showingAddMeasurements) {
            AddMeasurementsView()
                .environmentObject(measurementsManager)
                .environmentObject(authManager)
        }
        .sheet(item: $selectedMeasurement) { measurement in
            MeasurementDetailView(
                measurement: measurement,
                previousMeasurement: getPreviousMeasurement(for: measurement)
            )
            .environmentObject(measurementsManager)
            .environmentObject(authManager)
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                Task {
                    await loadInitialData()
                }
            }
        }
        .refreshable {
            await loadInitialData()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.arms.open")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No hay medidas registradas")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Agrega tus primeras medidas para comenzar a hacer seguimiento de tu progreso")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Agregar Primera Medida") {
                showingAddMeasurements = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
    
    // MARK: - Summary Card
    private func summaryCard(for measurement: BodyMeasurements) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Última Medición")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(measurement.fecha.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                }
                
                Spacer()
                
                // Indicador de cambio si hay medición previa
                if let previous = getPreviousMeasurement(for: measurement) {
                    let weightDiff = measurement.peso - previous.peso
                    HStack(spacing: 4) {
                        Image(systemName: weightDiff > 0 ? "arrow.up.circle.fill" : weightDiff < 0 ? "arrow.down.circle.fill" : "equal.circle.fill")
                            .foregroundColor(weightDiff > 0 ? .red : weightDiff < 0 ? .green : .secondary)
                        Text(String(format: "%.1f kg", abs(weightDiff)))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Métricas principales
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Peso")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f kg", measurement.peso))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("IMC")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    let imc = measurement.peso / pow(measurement.altura / 100, 2)
                    Text(String(format: "%.1f", imc))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(imcColor(imc))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cintura")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f cm", measurement.cintura))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
            }
            
            // Mini gráfico de progreso
            if measurementsManager.measurementsHistory.count > 1 {
                progressChart
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            selectedMeasurement = measurement
        }
    }
    
    // MARK: - Progress Chart
    private var progressChart: some View {
        let recentMeasurements = Array(measurementsManager.measurementsHistory.prefix(7).reversed())
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Progreso de Peso")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Chart(recentMeasurements, id: \.id) { measurement in
                LineMark(
                    x: .value("Fecha", measurement.fecha),
                    y: .value("Peso", measurement.peso)
                )
                .foregroundStyle(.green)
                
                PointMark(
                    x: .value("Fecha", measurement.fecha),
                    y: .value("Peso", measurement.peso)
                )
                .foregroundStyle(.green)
                .symbolSize(30)
            }
            .frame(height: 80)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }
    }
    
    // MARK: - Measurements List
    private var measurementsListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historial de Mediciones")
                .font(.headline)
                .fontWeight(.bold)
            
            ForEach(measurementsManager.measurementsHistory, id: \.id) { measurement in
                MeasurementRowView(
                    measurement: measurement,
                    previousMeasurement: getPreviousMeasurement(for: measurement)
                )
                .onTapGesture {
                    selectedMeasurement = measurement
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func loadInitialData() async {
        guard let userId = authManager.user?.id else { return }
        await measurementsManager.loadMeasurementsHistory(userId: userId)
    }
    
    private func getPreviousMeasurement(for measurement: BodyMeasurements) -> BodyMeasurements? {
        guard let index = measurementsManager.measurementsHistory.firstIndex(where: { $0.id == measurement.id }),
              index + 1 < measurementsManager.measurementsHistory.count else {
            return nil
        }
        return measurementsManager.measurementsHistory[index + 1]
    }
    
    private func imcColor(_ imc: Double) -> Color {
        switch imc {
        case ..<18.5: return .blue
        case 18.5..<25: return .green
        case 25..<30: return .orange
        default: return .red
        }
    }
}

// MARK: - Measurement Row View
struct MeasurementRowView: View {
    let measurement: BodyMeasurements
    let previousMeasurement: BodyMeasurements?
    
    var body: some View {
        HStack {
            // Fecha
            VStack(alignment: .leading, spacing: 2) {
                Text(measurement.fecha.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(measurement.fecha.formatted(.dateTime.year()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .leading)
            
            // Métricas principales
            HStack(spacing: 20) {
                MetricChange(
                    value: measurement.peso,
                    previous: previousMeasurement?.peso,
                    format: "%.1f kg",
                    label: "Peso"
                )
                
                MetricChange(
                    value: measurement.cintura,
                    previous: previousMeasurement?.cintura,
                    format: "%.0f cm",
                    label: "Cintura"
                )
            }
            
            Spacer()
            
            // Indicador de más detalles
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Metric Change View
struct MetricChange: View {
    let value: Double
    let previous: Double?
    let format: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text(String(format: format, value))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let prev = previous {
                    let diff = value - prev
                    if abs(diff) > 0.01 {
                        Text(String(format: diff > 0 ? "+%.1f" : "%.1f", diff))
                            .font(.caption2)
                            .foregroundColor(diff > 0 ? .red : .green)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
}

// MARK: - Button Styles (mantener los existentes)
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .fontWeight(.semibold)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
