//
//  BodyMeasurementsView.swift
//  bulkup
//
//  Body: the latest measurement as a strip of numbers, the weight as one
//  quiet line, the history as rows in a slab. Deltas are signed and neutral:
//  in a bulk, going up is the plan.
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
                title: "Medidas corporales",
                subtitle: "Haz seguimiento de tu composición corporal y progreso físico",
                features: [
                    "Registro de peso, cintura, cuello y mas",
                    "Historial de mediciones con gráficos",
                    "Cálculo de IMC y composición corporal",
                    "Tendencias y cambios entre mediciones"
                ]
            )
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
                    .environmentObject(authManager)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                    if measurementsManager.isLoading && measurementsManager.measurementsHistory.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if measurementsManager.measurementsHistory.isEmpty {
                        emptyState
                    } else {
                        if let latest = measurementsManager.measurementsHistory.first {
                            summarySlab(for: latest)
                        }
                        if measurementsManager.measurementsHistory.count > 1 {
                            weightChart
                        }
                        historySlab
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xl)
            }
            .background(BulkUpGround())
            .navigationTitle("Medidas corporales")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddMeasurements = true } label: {
                        Image(systemName: "plus")
                            .font(.system(.body, weight: .semibold))
                            .foregroundColor(BulkUpColors.accentText)
                    }
                    .accessibilityLabel("Añadir medida")
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
                    Task { await loadInitialData() }
                }
            }
            .refreshable { await loadInitialData() }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Sin medidas todavía")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)
            Text("Registra peso, cintura y cuello y verás aquí tu evolución y tu composición corporal.")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button { showingAddMeasurements = true } label: {
                Text("Añadir primera medida")
                    .primaryButtonStyle()
            }
            .pressable()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .slab()
    }

    // MARK: - Latest

    private func summarySlab(for m: BodyMeasurements) -> some View {
        let previous = getPreviousMeasurement(for: m)
        let imc = m.peso / pow(m.altura / 100, 2)
        return Button { selectedMeasurement = m } label: {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Text("Última medición")
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)
                    Spacer()
                    Text(m.fecha.formatted(.dateTime.day().month(.abbreviated).year().locale(LanguageManager.shared.locale)))
                        .font(BulkUpFont.numeric(.footnote))
                        .foregroundColor(BulkUpColors.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
                StatsStrip(cells: [
                    StatCell(value: BulkUpFormat.decimal(m.peso), unit: "kg", label: "Peso",
                             detail: previous.map { BulkUpFormat.signed(m.peso - $0.peso) + " kg" }),
                    StatCell(value: BulkUpFormat.decimal(imc), label: "IMC",
                             detail: previous.map { BulkUpFormat.signed(imc - $0.peso / pow($0.altura / 100, 2)) }),
                    StatCell(value: BulkUpFormat.decimal(m.cintura, fraction: 0), unit: "cm", label: "Cintura",
                             detail: previous.map { BulkUpFormat.signed(m.cintura - $0.cintura, fraction: 0) + " cm" }),
                ], bare: true)
                if let c = measurementsManager.bodyComposition {
                    Text(String(format: NSLocalizedString("Grasa %@ %% · Masa magra %@ kg", comment: ""),
                                BulkUpFormat.decimal(c.bodyFatPercentage), BulkUpFormat.decimal(c.leanMass)))
                        .font(BulkUpFont.numeric(.footnote))
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .slab()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Weight line

    private var recent: [BodyMeasurements] {
        Array(measurementsManager.measurementsHistory.prefix(12).reversed())
    }

    private var weightChart: some View {
        let points = recent
        let weights = points.map(\.peso)
        let lo = (weights.min() ?? 0) - 1
        let hi = (weights.max() ?? 0) + 1
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("Peso")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)
                Spacer()
                Text(String(format: NSLocalizedString("Últimas %lld mediciones", comment: ""), points.count))
                    .font(BulkUpFont.numeric(.footnote))
                    .foregroundColor(BulkUpColors.textSecondary)
            }
            Chart {
                ForEach(points, id: \.id) { m in
                    LineMark(x: .value("Fecha", m.fecha), y: .value("Peso", m.peso))
                        .foregroundStyle(BulkUpColors.complete)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.monotone)
                    PointMark(x: .value("Fecha", m.fecha), y: .value("Peso", m.peso))
                        .foregroundStyle(BulkUpColors.complete)
                        .symbolSize(m.id == points.last?.id ? 110 : 52)
                }
                if let last = points.last {
                    PointMark(x: .value("Fecha", last.fecha), y: .value("Peso", last.peso))
                        .foregroundStyle(.clear)
                        .annotation(position: .top, spacing: 6) {
                            Text("\(BulkUpFormat.decimal(last.peso)) kg")
                                .font(BulkUpFont.numeric(.caption2, weight: .semibold))
                                .foregroundColor(BulkUpColors.textPrimary)
                        }
                }
            }
            .chartYScale(domain: lo...hi)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(BulkUpColors.line)
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated).locale(LanguageManager.shared.locale))
                        .font(.system(.caption2))
                        .foregroundStyle(BulkUpColors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(BulkUpColors.line)
                    AxisValueLabel()
                        .font(.system(.caption2).monospacedDigit())
                        .foregroundStyle(BulkUpColors.textTertiary)
                }
            }
            .chartPlotStyle { $0.padding(.top, 14) }
            .frame(height: 150)
        }
        .padding(Spacing.md)
        .slab()
    }

    // MARK: - History

    private var historySlab: some View {
        let history = measurementsManager.measurementsHistory
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Historial")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)
                Spacer()
                Text(String(format: NSLocalizedString("%lld mediciones", comment: ""), history.count))
                    .font(BulkUpFont.numeric(.footnote))
                    .foregroundColor(BulkUpColors.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xs)

            ForEach(Array(history.enumerated()), id: \.element.id) { i, m in
                Button { selectedMeasurement = m } label: {
                    MeasurementRowView(measurement: m, previousMeasurement: getPreviousMeasurement(for: m),
                                       showsSeparator: i < history.count - 1)
                }
                .buttonStyle(.plain)
            }
        }
        .slab()
    }

    // MARK: - Helpers

    private func loadInitialData() async {
        #if DEBUG
        if DesignPreview.isActive { return }
        #endif
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
}

// MARK: - Measurement row
struct MeasurementRowView: View {
    let measurement: BodyMeasurements
    let previousMeasurement: BodyMeasurements?
    var showsSeparator: Bool = true

    var body: some View {
        SlabRow(showsSeparator: showsSeparator) {
            HStack(spacing: Spacing.sm + 2) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(measurement.fecha.formatted(.dateTime.day().month(.abbreviated).locale(LanguageManager.shared.locale)))
                        .font(BulkUpFont.numeric(.subheadline, weight: .medium))
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text(measurement.fecha.formatted(.dateTime.year()))
                        .font(BulkUpFont.numeric(.caption2))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
                .frame(width: 62, alignment: .leading)

                MetricChange(value: measurement.peso, previous: previousMeasurement?.peso, unit: "kg", fraction: 1, label: "Peso")
                MetricChange(value: measurement.cintura, previous: previousMeasurement?.cintura, unit: "cm", fraction: 0, label: "Cintura")

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundColor(BulkUpColors.textTertiary)
            }
            .contentShape(Rectangle())
        }
    }
}

/// A value with its unit and a signed, neutral delta from the previous entry.
struct MetricChange: View {
    let value: Double
    let previous: Double?
    var unit: String = "kg"
    var fraction: Int = 1
    let label: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(BulkUpFormat.decimal(value, fraction: fraction)) \(unit)")
                    .font(BulkUpFont.numeric(.subheadline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                if let previous, abs(value - previous) >= pow(10, -Double(fraction)) / 2 {
                    Text(BulkUpFormat.signed(value - previous, fraction: fraction))
                        .font(BulkUpFont.numeric(.caption2, weight: .medium))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }
            Text(label)
                .font(.system(.caption2))
                .foregroundColor(BulkUpColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            .foregroundColor(Color.onFill(color))
            .cornerRadius(CornerRadius.medium)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            .fontWeight(.semibold)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
