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
    @ObservedObject private var measurementsManager = BodyMeasurementsManager.shared
    @ObservedObject private var storeKit = StoreKitManager.shared
    @State private var showingAddMeasurements = false
    @State private var showingSubscription = false
    @State private var selectedMeasurement: BodyMeasurements?
    @State private var hasAppeared = false

    var body: some View {
        if !storeKit.isSubscribed {
            SubscriptionRequiredView(
                onSubscribe: { showingSubscription = true },
                title: "Medidas Corporales",
                subtitle: "Haz seguimiento de tu composicion corporal y progreso fisico",
                features: [
                    "Registro de peso, cintura, cuello y mas",
                    "Historial de mediciones con graficos",
                    "Calculo de IMC y composicion corporal",
                    "Tendencias y cambios entre mediciones"
                ]
            )
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
                    .environmentObject(authManager)
            }
        } else {
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
        .background(BulkUpColors.background.ignoresSafeArea())
        .navigationTitle("Medidas Corporales")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddMeasurements = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.accent)
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
        } // else (subscribed)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "figure.arms.open",
            title: "No hay medidas registradas",
            subtitle: "Agrega tus primeras medidas para comenzar a hacer seguimiento de tu progreso",
            color: BulkUpColors.accent,
            actionTitle: "Agregar Primera Medida",
            actionIcon: "plus.circle.fill",
            action: { showingAddMeasurements = true }
        )
    }

    // MARK: - Summary Card
    private func summaryCard(for measurement: BodyMeasurements) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Última Medición")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                    Text(measurement.fecha.formatted(date: .abbreviated, time: .omitted))
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)
                }

                Spacer()

                // Indicador de cambio si hay medición previa
                if let previous = getPreviousMeasurement(for: measurement) {
                    let weightDiff = measurement.peso - previous.peso
                    HStack(spacing: 4) {
                        Image(systemName: weightDiff > 0 ? "arrow.up.circle.fill" : weightDiff < 0 ? "arrow.down.circle.fill" : "equal.circle.fill")
                            .foregroundColor(weightDiff > 0 ? BulkUpColors.error : weightDiff < 0 ? BulkUpColors.success : BulkUpColors.textSecondary)
                        Text(String(format: "%.1f kg", abs(weightDiff)))
                            .font(BulkUpFont.dataLabel())
                            .foregroundColor(BulkUpColors.textPrimary)
                    }
                }
            }

            // Métricas principales
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Peso")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                    Text(String(format: "%.1f kg", measurement.peso))
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.textPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("IMC")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                    let imc = measurement.peso / pow(measurement.altura / 100, 2)
                    Text(String(format: "%.1f", imc))
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(imcColor(imc))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Cintura")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                    Text(String(format: "%.0f cm", measurement.cintura))
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.textPrimary)
                }

                Spacer()
            }

            // Mini gráfico de progreso
            if measurementsManager.measurementsHistory.count > 1 {
                progressChart
            }
        }
        .cardStyle()
        .onTapGesture {
            selectedMeasurement = measurement
        }
    }

    // MARK: - Progress Chart
    private var progressChart: some View {
        let recentMeasurements = Array(measurementsManager.measurementsHistory.prefix(7).reversed())

        return VStack(alignment: .leading, spacing: 8) {
            Text("Progreso de Peso")
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)

            Chart(recentMeasurements, id: \.id) { measurement in
                LineMark(
                    x: .value("Fecha", measurement.fecha),
                    y: .value("Peso", measurement.peso)
                )
                .foregroundStyle(BulkUpColors.training)

                PointMark(
                    x: .value("Fecha", measurement.fecha),
                    y: .value("Peso", measurement.peso)
                )
                .foregroundStyle(BulkUpColors.training)
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
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Historial de Mediciones")
                .sectionHeader()

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
        case ..<18.5: return BulkUpColors.training
        case 18.5..<25: return BulkUpColors.success
        case 25..<30: return BulkUpColors.warning
        default: return BulkUpColors.error
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
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)
                Text(measurement.fecha.formatted(.dateTime.year()))
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
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
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .flatCardStyle()
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
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)

            HStack(spacing: 4) {
                Text(String(format: format, value))
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)

                if let prev = previous {
                    let diff = value - prev
                    if abs(diff) > 0.01 {
                        Text(String(format: diff > 0 ? "+%.1f" : "%.1f", diff))
                            .font(BulkUpFont.caption())
                            .foregroundColor(diff > 0 ? BulkUpColors.error : BulkUpColors.success)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = BulkUpColors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BulkUpFont.cardTitle())
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.medium)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            .fontWeight(.semibold)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
