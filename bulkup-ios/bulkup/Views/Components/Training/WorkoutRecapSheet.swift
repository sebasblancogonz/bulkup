//
//  WorkoutRecapSheet.swift
//  bulkup
//
//  Recap of a finished workout day: totals, sensations, and every logged set.
//  Weights and reps stay editable here so a mistyped set can be fixed after the
//  session is over, without re-entering workout mode.
//

import SwiftUI

struct WorkoutRecapSheet: View {
    let dayData: TrainingDay

    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var workoutSession = WorkoutSessionManager.shared
    @Environment(\.dismiss) private var dismiss

    /// In-progress text, so a half-typed "12." isn't reformatted mid-keystroke.
    @State private var drafts: [String: String] = [:]
    @State private var feedback: WorkoutFeedback?
    @State private var showFeedbackEditor = false
    @State private var isSaving = false
    /// Last set of an exercise awaiting removal confirmation (it has data).
    @State private var pendingRemoval: PendingRemoval?

    private struct PendingRemoval: Identifiable {
        let exerciseIndex: Int
        let setIndex: Int
        var id: String { "\(exerciseIndex)-\(setIndex)" }
    }

    private var normalizedDay: String {
        dayData.day.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }

    private var currentWeekString: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: trainingManager.getWeekStart(trainingManager.selectedWeek))
    }

    private var exercises: [Exercise] {
        dayData.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    totalsGrid
                    feedbackSection

                    ForEach(exercises, id: \.orderIndex) { exercise in
                        exerciseSection(exercise)
                    }

                    Color.clear.frame(height: 20)
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(BulkUpColors.background)
            .navigationTitle(dayData.workoutName ?? dayData.day.capitalized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        save()
                    } label: {
                        if isSaving {
                            ProgressView().tint(BulkUpColors.accent)
                        } else {
                            Text("Guardar").fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                    .foregroundColor(BulkUpColors.accentText)
                }
            }
        }
        .onAppear(perform: loadFeedback)
        .confirmationDialog(
            "Eliminar serie",
            isPresented: Binding(
                get: { pendingRemoval != nil },
                set: { if !$0 { pendingRemoval = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingRemoval
        ) { removal in
            Button("Eliminar la serie \(removal.setIndex + 1)", role: .destructive) {
                if let exercise = exercises.first(where: { $0.orderIndex == removal.exerciseIndex }) {
                    removeSet(exercise, at: removal.setIndex)
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: { _ in
            Text("Se borrarán el peso, las reps y el vídeo de esta serie.")
        }
        .sheet(isPresented: $showFeedbackEditor, onDismiss: loadFeedback) {
            WorkoutFeedbackView(dayName: dayData.day, planId: trainingManager.trainingPlanId,
                                weekStart: currentWeekString)
        }
    }

    // MARK: - Totals

    private var totalsGrid: some View {
        HStack(spacing: Spacing.md) {
            totalCell(value: "\(Int(totalVolume))", unit: "kg", label: "Volumen")
            totalCell(value: "\(loggedSets)", unit: "", label: "Series")
            totalCell(value: "\(loggedExercises)/\(exercises.count)", unit: "", label: "Ejercicios")
        }
    }

    private func totalCell(value: String, unit: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(BulkUpColors.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }
            Text(label)
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
    }

    // MARK: - Sensations

    private var feedbackSection: some View {
        Button {
            showFeedbackEditor = true
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Text("SENSACIONES")
                        .font(BulkUpFont.badge())
                        .tracking(0.5)
                        .foregroundColor(BulkUpColors.textTertiary)
                    Spacer()
                    Text(feedback == nil ? "Registrar" : "Editar")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(BulkUpColors.accentText)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BulkUpColors.accentText)
                }

                if let feedback {
                    HStack(spacing: Spacing.sm) {
                        if let emoji = WorkoutFeedbackManager.emoji(for: feedback.rating) {
                            Text(emoji).font(.system(size: 26))
                        }
                        if !feedback.tags.isEmpty {
                            Text(feedback.tags.joined(separator: " · "))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(BulkUpColors.textSecondary)
                        }
                        Spacer()
                    }
                    if let note = feedback.note, !note.isEmpty {
                        Text(note)
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    if !feedback.photoFilenames.isEmpty {
                        Text("\(feedback.photoFilenames.count) foto(s)")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textTertiary)
                    }
                } else {
                    Text("Sin registrar")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(BulkUpColors.surface)
            .cornerRadius(CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func loadFeedback() {
        feedback = WorkoutFeedbackManager.shared.feedback(
            planId: trainingManager.trainingPlanId,
            dayName: dayData.day,
            weekStart: currentWeekString
        )
    }

    // MARK: - Exercises

    @ViewBuilder
    private func exerciseSection(_ exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(effectiveName(exercise))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(BulkUpColors.textPrimary)

            if !exercise.weightTracking {
                Text("Sin seguimiento de peso")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)
            } else {
                ForEach(0..<sets(exercise), id: \.self) { setIndex in
                    HStack(spacing: Spacing.sm) {
                        Text("S\(setIndex + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(BulkUpColors.textSecondary)
                            .frame(width: 32, alignment: .leading)

                        numberField(
                            placeholder: "—",
                            decimal: true,
                            binding: weightBinding(exercise, setIndex)
                        )
                        Text("kg")
                            .font(.system(size: 12))
                            .foregroundColor(BulkUpColors.textTertiary)

                        Text("×")
                            .font(.system(size: 13))
                            .foregroundColor(BulkUpColors.textTertiary)

                        numberField(
                            placeholder: "\(plannedReps(exercise, setIndex))",
                            decimal: false,
                            binding: repsBinding(exercise, setIndex)
                        )
                        Text("reps")
                            .font(.system(size: 12))
                            .foregroundColor(BulkUpColors.textTertiary)

                        Spacer()
                    }
                    .contextMenu {
                        if sets(exercise) > 1 {
                            Button(role: .destructive) {
                                requestRemoveSet(exercise, at: setIndex)
                            } label: {
                                Label("Eliminar serie", systemImage: "trash")
                            }
                        }
                    }
                }

                // Forgot a set, or logged one too many: fix it here too.
                HStack(spacing: Spacing.md) {
                    Button {
                        trainingManager.addSet(
                            day: normalizedDay, exerciseIndex: exercise.orderIndex, plannedSets: exercise.sets
                        )
                    } label: {
                        Label("Añadir serie", systemImage: "plus.circle")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BulkUpColors.accentText)
                    }
                    if sets(exercise) > 1 {
                        Button {
                            requestRemoveSet(exercise, at: sets(exercise) - 1)
                        } label: {
                            Label("Quitar serie", systemImage: "minus.circle")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(BulkUpColors.textTertiary)
                        }
                    }
                    Spacer()
                    if sets(exercise) != exercise.sets {
                        Text("Plan: \(exercise.sets)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(BulkUpColors.textTertiary)
                    }
                }
                .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
    }

    private func numberField(placeholder: String, decimal: Bool, binding: Binding<String>) -> some View {
        TextField(placeholder, text: binding)
            .keyboardType(decimal ? .decimalPad : .numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 15, weight: .medium, design: .monospaced))
            .foregroundColor(BulkUpColors.textPrimary)
            .frame(width: 56, height: 34)
            .background(
                RoundedRectangle(cornerRadius: 8).fill(BulkUpColors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(BulkUpColors.textTertiary.opacity(0.15), lineWidth: 1)
            )
    }

    // MARK: - Bindings

    /// Sets logged this week for the exercise (plan count ± user adjustments).
    private func sets(_ exercise: Exercise) -> Int {
        trainingManager.effectiveSets(for: exercise, day: normalizedDay)
    }

    private func requestRemoveSet(_ exercise: Exercise, at setIndex: Int) {
        let k = key(exercise, setIndex)
        let hasData = (trainingManager.weights[k] ?? 0) > 0 || (trainingManager.setReps[k] ?? 0) > 0
            || WorkoutVideoStore.hasVideo(for: k)
        if hasData {
            pendingRemoval = PendingRemoval(exerciseIndex: exercise.orderIndex, setIndex: setIndex)
        } else {
            removeSet(exercise, at: setIndex)
        }
    }

    private func removeSet(_ exercise: Exercise, at setIndex: Int) {
        // Drop in-progress drafts for this exercise: the slots just shifted.
        drafts = drafts.filter { !$0.key.hasSuffix(key(exercise, 0).dropLast(2)) && !$0.key.contains("-\(exercise.orderIndex)-") }
        workoutSession.removeSet(
            day: normalizedDay, exerciseIndex: exercise.orderIndex, exerciseName: effectiveName(exercise),
            plannedSets: exercise.sets, setIndex: setIndex, trainingManager: trainingManager
        )
    }

    private func effectiveName(_ exercise: Exercise) -> String {
        workoutSession.effectiveExerciseName(
            day: normalizedDay, exerciseIndex: exercise.orderIndex, planName: exercise.name
        )
    }

    private func key(_ exercise: Exercise, _ setIndex: Int) -> String {
        trainingManager.generateWeightKey(
            day: normalizedDay,
            exerciseIndex: exercise.orderIndex,
            exerciseName: effectiveName(exercise),
            setIndex: setIndex,
            weekStart: currentWeekString
        )
    }

    /// Plan target for one set — "10, 8, 6" → 10/8/6 per set, "8-12" → 12.
    private func plannedReps(_ exercise: Exercise, _ setIndex: Int) -> Int {
        TrainingManager.plannedReps(exercise.reps, setIndex: setIndex)
    }

    private func weightBinding(_ exercise: Exercise, _ setIndex: Int) -> Binding<String> {
        let k = key(exercise, setIndex)
        return Binding(
            get: {
                if let draft = drafts["w-\(k)"] { return draft }
                guard let w = trainingManager.weights[k], w > 0 else { return "" }
                return ExerciseWeightLogger.formatWeightString(w)
            },
            set: { newValue in
                // The decimal pad emits the locale separator; Double(_:) needs ".".
                let normalized = newValue.replacingOccurrences(of: ",", with: ".")
                drafts["w-\(k)"] = normalized
                trainingManager.updateWeight(
                    day: normalizedDay,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: effectiveName(exercise),
                    setIndex: setIndex,
                    weight: Double(normalized) ?? 0
                )
            }
        )
    }

    private func repsBinding(_ exercise: Exercise, _ setIndex: Int) -> Binding<String> {
        let k = key(exercise, setIndex)
        return Binding(
            get: {
                if let draft = drafts["r-\(k)"] { return draft }
                guard let r = trainingManager.setReps[k], r > 0 else { return "" }
                return "\(r)"
            },
            set: { newValue in
                drafts["r-\(k)"] = newValue
                trainingManager.updateReps(
                    day: normalizedDay,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: effectiveName(exercise),
                    setIndex: setIndex,
                    reps: Int(newValue) ?? 0
                )
            }
        )
    }

    // MARK: - Totals math

    private var loggedSets: Int {
        exercises.reduce(0) { acc, ex in
            acc + (0..<sets(ex)).filter { (trainingManager.weights[key(ex, $0)] ?? 0) > 0 }.count
        }
    }

    private var loggedExercises: Int {
        exercises.filter { ex in
            (0..<sets(ex)).contains { (trainingManager.weights[key(ex, $0)] ?? 0) > 0 }
        }.count
    }

    private var totalVolume: Double {
        exercises.reduce(0.0) { acc, ex in
            acc + (0..<sets(ex)).reduce(0.0) { sum, setIndex in
                let k = key(ex, setIndex)
                let weight = trainingManager.weights[k] ?? 0
                guard weight > 0 else { return sum }
                let reps = trainingManager.setReps[k] ?? plannedReps(ex, setIndex)
                return sum + weight * Double(reps)
            }
        }
    }

    // MARK: - Save

    private func save() {
        guard let user = authManager.user else { dismiss(); return }
        isSaving = true
        Task {
            for exercise in exercises where exercise.weightTracking {
                let noteKey = trainingManager.generateWeightKey(
                    day: normalizedDay,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: effectiveName(exercise),
                    weekStart: currentWeekString
                )
                await trainingManager.saveWeightsToDatabase(
                    day: normalizedDay,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: effectiveName(exercise),
                    note: trainingManager.backendExerciseNotes[noteKey] ?? "",
                    userId: user.id
                )
            }
            isSaving = false
            dismiss()
        }
    }
}
