//
//  ExerciseDetailView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 20/8/25.
//


import SwiftUI
import Charts

struct ExerciseDetailView: View {
    let exercise: RMExercise
    @ObservedObject var rmManager = RMManager.shared
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var notificationManager = RMNotificationManager.shared

    @State private var showAddForm = false
    @State private var formData = RMFormData()
    @State private var editingRecordId: String?

    private var exerciseRecords: [PersonalRecord] {
        rmManager.getRecordsForExercise(exercise.id)
    }

    private var bestRecord: PersonalRecord? {
        rmManager.getBestRecordForExercise(exercise.id)
    }

    private var exerciseStats: ExerciseStats {
        calculateExerciseStats()
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                // Header
                exerciseHeader

                // Stats Cards
                statsCards

                // RM Percentages Chart
                if let bestRM = bestRecord {
                    rmPercentagesView(bestRM: bestRM)
                }

                // Progress Chart
                if exerciseRecords.count > 1 {
                    progressChart
                }

                // Records List
                recordsList
            }
            .padding()
        }
        .background(BulkUpColors.background.ignoresSafeArea())
    .safeAreaInset(edge: .bottom) {
        Color.clear.frame(height: 48)
    }
        .navigationTitle(exercise.nameEs)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddRecord() }) {
                    Image(systemName: "plus")
                        .foregroundColor(BulkUpColors.accent)
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            AddRecordFormView(
                formData: $formData,
                exercises: [exercise],
                isEditing: editingRecordId != nil,
                isSubmitting: rmManager.isSubmitting,
                onSubmit: handleSubmit,
                onCancel: resetForm
            )
        }
    }

    // MARK: - Subviews

    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.nameEs)
                        .font(BulkUpFont.sectionHeader())
                        .foregroundColor(BulkUpColors.textPrimary)

                    Text(exercise.categoryEs.capitalized)
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(BulkUpColors.surfaceElevated)
                        .cornerRadius(CornerRadius.small)
                }

                Spacer()

                Image(systemName: "dumbbell.fill")
                    .font(.title)
                    .foregroundColor(BulkUpColors.training)
            }
        }
        .cardStyle()
    }

    private var statsCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Spacing.md) {
            RMStatCard(
                title: "Mejor PR",
                value: bestRecord?.weight.formatted() ?? "0",
                subtitle: "kg",
                color: BulkUpColors.accent
            )

            RMStatCard(
                title: "Total Sets",
                value: "\(exerciseRecords.count)",
                subtitle: "registrados",
                color: BulkUpColors.success
            )

            RMStatCard(
                title: "Progreso",
                value: "\(exerciseStats.progressPercentage.formatted(.number.precision(.fractionLength(1))))%",
                subtitle: "desde inicio",
                color: BulkUpColors.secondary
            )

            RMStatCard(
                title: "Volumen Total",
                value: "\(exerciseStats.totalVolume)",
                subtitle: "kg × reps",
                color: BulkUpColors.training
            )
        }
    }

    private func rmPercentagesView(bestRM: PersonalRecord) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Porcentajes del 1RM")
                .sectionHeader()
                .padding(.horizontal)

            if let estimatedRM = RMCalculator.calculateHybridRM(weight: bestRM.weight, reps: bestRM.reps) {
                let percentages = RMCalculator.calculatePercentages(oneRM: estimatedRM)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.sm) {
                    ForEach(percentages, id: \.percentage) { item in
                        VStack(spacing: 2) {
                            Text("\(item.percentage)%")
                                .font(BulkUpFont.caption())
                                .fontWeight(.bold)
                                .foregroundColor(BulkUpColors.training)

                            Text("\(item.weight.formatted(.number.precision(.fractionLength(1)))) kg")
                                .font(BulkUpFont.caption())
                                .fontWeight(.semibold)
                                .foregroundColor(BulkUpColors.textPrimary)

                            Text(item.reps)
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .background(BulkUpColors.surfaceElevated)
                        .cornerRadius(CornerRadius.small)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.large).stroke(BulkUpColors.border, lineWidth: 0.5))
    }

    private var progressChart: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Progreso Histórico")
                .sectionHeader()
                .padding(.horizontal)

            let chartData = exerciseRecords.enumerated().map { index, record in
                ChartDataPoint(
                    index: index,
                    date: record.dateValue,
                    estimatedRM: RMCalculator.calculateHybridRM(weight: record.weight, reps: record.reps) ?? 0
                )
            }

            Chart(chartData) { point in
                LineMark(
                    x: .value("Sesión", point.index),
                    y: .value("RM Estimado", point.estimatedRM)
                )
                .foregroundStyle(BulkUpColors.training)
                .symbol(Circle().strokeBorder(lineWidth: 2))
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.large).stroke(BulkUpColors.border, lineWidth: 0.5))
    }

    private var recordsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Historial Completo")
                    .sectionHeader()

                Spacer()

                Button(action: { showAddRecord() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Añadir")
                    }
                    .font(BulkUpFont.caption())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BulkUpColors.training)
                    .foregroundColor(Color.onFill(BulkUpColors.training))
                    .cornerRadius(CornerRadius.small)
                }
            }
            .padding(.horizontal)

            if exerciseRecords.isEmpty {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "calendar.badge.plus")
                        .font(BulkUpFont.screenTitle())
                        .foregroundColor(BulkUpColors.textTertiary)

                    Text("No hay registros")
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textSecondary)

                    Text("Añade tu primer récord para este ejercicio")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(exerciseRecords) { record in
                    RecordRowView(
                        record: record,
                        bestRecord: bestRecord,
                        onEdit: { editRecord(record) },
                        onDelete: { deleteRecord(record) }
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.large).stroke(BulkUpColors.border, lineWidth: 0.5))
    }

    // MARK: - Actions

    private func showAddRecord() {
        formData = RMFormData(exerciseId: exercise.id)
        editingRecordId = nil
        showAddForm = true
    }

    private func editRecord(_ record: PersonalRecord) {
        let formatter = ISO8601DateFormatter()
        formData = RMFormData(
            exerciseId: record.exerciseId,
            weight: String(record.weight),
            reps: String(record.reps),
            date: formatter.date(from: record.date) ?? Date(),
            notes: record.notes ?? ""
        )
        editingRecordId = record.id
        showAddForm = true
    }

    private func deleteRecord(_ record: PersonalRecord) {
        guard let token = authManager.user?.token else { return }

        Task {
            let success = await rmManager.deleteRecord(recordId: record.id, token: token)

            await MainActor.run {
                if success {
                    notificationManager.showNotification(.success, message: String(localized: "Récord eliminado"))
                } else {
                    notificationManager.showNotification(.error, message: String(localized: "Error al eliminar"))
                }
            }
        }
    }

    private func handleSubmit() {
        guard let token = authManager.user?.token else { return }

        Task {
            let success: Bool

            if let recordId = editingRecordId {
                success = await rmManager.updateRecord(
                    recordId: recordId,
                    recordData: formData.asDictionary,
                    token: token
                )
            } else {
                success = await rmManager.createRecord(
                    formData.asDictionary,
                    token: token
                )
            }

            await MainActor.run {
                if success {
                    resetForm()
                    let message = editingRecordId != nil ? String(localized: "Récord actualizado") : String(localized: "Récord creado")
                    notificationManager.showNotification(.success, message: message)
                } else {
                    notificationManager.showNotification(.error, message: String(localized: "Error al guardar"))
                }
            }
        }
    }

    private func resetForm() {
        formData = RMFormData()
        editingRecordId = nil
        showAddForm = false
    }

    // MARK: - Helper Methods

    private func calculateExerciseStats() -> ExerciseStats {
        guard !exerciseRecords.isEmpty else {
            return ExerciseStats(
                totalVolume: 0,
                progressPercentage: 0,
                bestRM: 0,
                averageWeight: 0
            )
        }

        let totalVolume = exerciseRecords.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        let averageWeight = exerciseRecords.map(\.weight).reduce(0, +) / Double(exerciseRecords.count)

        let sortedByDate = exerciseRecords.sorted { $0.dateValue < $1.dateValue }
        let progressPercentage: Double

        if sortedByDate.count >= 2 {
            let firstRM = RMCalculator.calculateHybridRM(weight: sortedByDate.first!.weight, reps: sortedByDate.first!.reps) ?? 0
            let lastRM = RMCalculator.calculateHybridRM(weight: sortedByDate.last!.weight, reps: sortedByDate.last!.reps) ?? 0
            progressPercentage = firstRM > 0 ? ((lastRM - firstRM) / firstRM) * 100 : 0
        } else {
            progressPercentage = 0
        }

        let bestRM = exerciseRecords.compactMap { RMCalculator.calculateHybridRM(weight: $0.weight, reps: $0.reps) }.max() ?? 0

        return ExerciseStats(
            totalVolume: Int(totalVolume),
            progressPercentage: progressPercentage,
            bestRM: bestRM,
            averageWeight: averageWeight
        )
    }
}

// MARK: - Supporting Views and Models

struct ExerciseStats {
    let totalVolume: Int
    let progressPercentage: Double
    let bestRM: Double
    let averageWeight: Double
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let date: Date
    let estimatedRM: Double
}

struct RMStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(title))
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)

            Text(value)
                .font(BulkUpFont.heroStat())
                .foregroundColor(color)

            Text(LocalizedStringKey(subtitle))
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.small)
    }
}

struct RecordRowView: View {
    let record: PersonalRecord
    let bestRecord: PersonalRecord?
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    private var estimatedRM: Double? {
        RMCalculator.calculateHybridRM(weight: record.weight, reps: record.reps)
    }

    private var percentage: Int {
        guard let rm = estimatedRM,
              let bestRM = bestRecord.flatMap({ RMCalculator.calculateHybridRM(weight: $0.weight, reps: $0.reps) }),
              bestRM > 0 else { return 0 }
        return Int((rm / bestRM) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatDate(record.date))
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textPrimary)

                    HStack(spacing: 12) {
                        Text("\(record.weight.formatted(.number.precision(.fractionLength(1)))) kg × \(record.reps)")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)

                        if let rm = estimatedRM {
                            Text("RM: \(rm.formatted(.number.precision(.fractionLength(1)))) kg")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.training)
                        }

                        if percentage > 0 {
                            Text("\(percentage)%")
                                .font(BulkUpFont.caption())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(percentageColor.opacity(0.2))
                                .foregroundColor(percentageColor)
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                HStack(spacing: Spacing.sm) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.training)
                    }

                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.error)
                    }
                }
            }

            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .italic()
                    .padding(.top, 2)
            }
        }
        .padding()
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.small)
        .confirmationDialog(
            "¿Eliminar récord?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) { onDelete() }
            Button("Cancelar", role: .cancel) { }
        }
    }

    private var percentageColor: Color {
        switch percentage {
        case 95...: return BulkUpColors.error
        case 85..<95: return BulkUpColors.warning
        case 70..<85: return BulkUpColors.accent
        default: return BulkUpColors.success
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}
