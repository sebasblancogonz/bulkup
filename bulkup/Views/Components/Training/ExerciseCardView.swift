//
//  ExerciseCardView.swift
//  bulkup
//
//  Premium card-based exercise row with full name, structured sets, weight logging.
//  Supports workout session mode with per-set check-off, failure toggle, and rest timer.
//

import SwiftUI
import SwiftData

struct ExerciseCardView: View {
    let exercise: Exercise
    let exerciseIndex: Int
    let dayName: String
    let currentDate: Date
    let isExpanded: Bool
    let onToggleExpand: () -> Void

    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var workoutSession: WorkoutSessionManager = .shared

    private var normalizedDayName: String {
        dayName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
    }

    private var completedSets: Int {
        trainingManager.getCompletedSets(
            day: normalizedDayName,
            exerciseIndex: exercise.orderIndex,
            exerciseName: exercise.name,
            totalSets: exercise.sets
        )
    }

    private var isSkipped: Bool {
        workoutSession.isActive && workoutSession.isExerciseSkipped(
            day: normalizedDayName, exerciseIndex: exercise.orderIndex
        )
    }

    private var allSetsLogged: Bool {
        if workoutSession.isActive {
            if isSkipped { return true }
            let total = exercise.sets + workoutSession.extraSets(day: normalizedDayName, exerciseIndex: exercise.orderIndex)
            return workoutSession.isExerciseComplete(
                day: normalizedDayName,
                exerciseIndex: exercise.orderIndex,
                totalSets: total
            )
        }
        return completedSets == exercise.sets && exercise.sets > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed row — always visible
            Button(action: {
                if !isSkipped { onToggleExpand() }
            }) {
                HStack(spacing: Spacing.md) {
                    // Completion indicator
                    ZStack {
                        Circle()
                            .stroke(
                                isSkipped ? BulkUpColors.textTertiary :
                                allSetsLogged ? BulkUpColors.accent : BulkUpColors.muscleDefault,
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)

                        if isSkipped {
                            Circle()
                                .fill(BulkUpColors.textTertiary.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Image(systemName: "forward.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(BulkUpColors.textTertiary)
                        } else if allSetsLogged {
                            Circle()
                                .fill(BulkUpColors.accent.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(BulkUpColors.accent)
                        } else if workoutSession.isActive {
                            let total = exercise.sets + workoutSession.extraSets(day: normalizedDayName, exerciseIndex: exercise.orderIndex)
                            let done = workoutSession.completedSetsCount(day: normalizedDayName, exerciseIndex: exercise.orderIndex, totalSets: total)
                            if done > 0 {
                                Text("\(done)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(BulkUpColors.accent)
                            }
                        } else if completedSets > 0 {
                            Text("\(completedSets)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(BulkUpColors.accent)
                        }
                    }

                    // Exercise name + metadata
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: Spacing.xs) {
                            Text(exercise.name)
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(
                                    isSkipped ? BulkUpColors.textTertiary :
                                    allSetsLogged ? BulkUpColors.textSecondary :
                                    BulkUpColors.textPrimary
                                )
                                .strikethrough(isSkipped, color: BulkUpColors.textTertiary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            if isSkipped {
                                Text("Omitido")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(BulkUpColors.textTertiary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(BulkUpColors.surfaceElevated)
                                    .cornerRadius(4)
                            }
                        }

                        if !isSkipped {
                            HStack(spacing: Spacing.xs) {
                                if exercise.restSeconds > 0 {
                                    Text("\(exercise.restSeconds)s descanso")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(BulkUpColors.textTertiary)
                                }

                                if let tempo = exercise.tempo, !tempo.isEmpty {
                                    Text("·")
                                        .foregroundColor(BulkUpColors.textTertiary)
                                    Text(tempo)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(BulkUpColors.textTertiary)
                                }
                            }

                            setRepsPills
                        }
                    }

                    Spacer()

                    if !isSkipped {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(BulkUpColors.textTertiary)
                    }
                }
                .padding(Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // Context menu for skip/unskip during workout
            .if(workoutSession.isActive) { view in
                view.contextMenu {
                    if isSkipped {
                        Button {
                            workoutSession.unskipExercise(day: normalizedDayName, exerciseIndex: exercise.orderIndex)
                        } label: {
                            Label("Restaurar ejercicio", systemImage: "arrow.uturn.backward")
                        }
                    } else {
                        Button(role: .destructive) {
                            workoutSession.skipExercise(day: normalizedDayName, exerciseIndex: exercise.orderIndex)
                        } label: {
                            Label("Omitir ejercicio", systemImage: "forward.fill")
                        }
                    }
                }
            }

            // Expanded weight logger (hidden when skipped)
            if !isSkipped {
                ExerciseWeightLogger(
                    exercise: exercise,
                    dayName: dayName,
                    workoutSession: workoutSession
                )
                .environmentObject(trainingManager)
                .environmentObject(authManager)
                .frame(maxHeight: isExpanded ? nil : 0)
                .clipped()
                .opacity(isExpanded ? 1 : 0)
            }
        }
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
        // Completed: accent left border
        .overlay(alignment: .leading) {
            if allSetsLogged {
                UnevenRoundedRectangle(
                    topLeadingRadius: CornerRadius.large,
                    bottomLeadingRadius: CornerRadius.large,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(BulkUpColors.accent)
                .frame(width: 3)
            }
        }
        .clipped()
        .opacity(isSkipped ? 0.6 : allSetsLogged ? 0.85 : 1.0)
        .padding(.horizontal, Spacing.screenH)
    }

    // MARK: - Sets/Reps Pills

    private var setRepsPills: some View {
        HStack(spacing: 4) {
            let repsComponents = exercise.reps
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            if repsComponents.count > 1 {
                ForEach(Array(repsComponents.enumerated()), id: \.offset) { idx, rep in
                    let isSetCompleted = idx < completedSets
                    Text(rep)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSetCompleted ? BulkUpColors.onAccent : BulkUpColors.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSetCompleted ? BulkUpColors.accent : BulkUpColors.surfaceElevated)
                        )
                }
            } else {
                Text("\(exercise.sets)×\(exercise.reps)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(BulkUpColors.surfaceElevated)
                    )
            }
        }
    }
}

// MARK: - Inline Weight Logger

struct ExerciseWeightLogger: View {
    let exercise: Exercise
    let dayName: String
    @ObservedObject var workoutSession: WorkoutSessionManager

    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager

    @State private var weightTexts: [String] = []
    @State private var repsTexts: [String] = []
    @State private var previousWeights: [Double?] = []
    @State private var localNote: String = ""
    @State private var isSaving = false
    @State private var showSaved = false
    @FocusState private var focusedSet: Int?

    private var normalizedDay: String {
        dayName.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }

    private var currentWeekString: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: trainingManager.getWeekStart(trainingManager.selectedWeek))
    }

    private var exerciseKey: String {
        trainingManager.generateWeightKey(
            day: normalizedDay,
            exerciseIndex: exercise.orderIndex,
            exerciseName: exercise.name,
            weekStart: currentWeekString
        )
    }

    private var isWorkoutMode: Bool {
        workoutSession.isActive
    }

    private var totalSetsCount: Int {
        exercise.sets + workoutSession.extraSets(day: normalizedDay, exerciseIndex: exercise.orderIndex)
    }

    private var defaultReps: String {
        let cleaned = exercise.reps.components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces) ?? exercise.reps
        if cleaned.contains("-") {
            return cleaned.split(separator: "-").last.map(String.init) ?? cleaned
        }
        return cleaned
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Divider()
                .background(BulkUpColors.border)

            // Notes from exercise plan
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            if exercise.weightTracking {
                if isWorkoutMode {
                    workoutModeContent
                } else {
                    normalModeContent
                }
            } else {
                Text("Sin seguimiento de peso")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
        .onAppear { loadInitialData() }
        .onChange(of: trainingManager.isFullyLoaded) { _, loaded in
            if loaded { loadInitialData() }
        }
        .onChange(of: trainingManager.selectedWeek) { _, _ in
            loadInitialData()
        }
    }

    // MARK: - Workout Mode Content

    @ViewBuilder
    private var workoutModeContent: some View {
        // Previous weights banner
        if hasPreviousWeights {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 10))
                Text("ANTERIOR")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundColor(BulkUpColors.textTertiary)
        }

        // Table header
        HStack(spacing: 0) {
            Text("SERIE")
                .frame(width: 40, alignment: .leading)
            Text("KG")
                .frame(width: 72, alignment: .center)
            Text("REPS")
                .frame(width: 56, alignment: .center)
            Spacer()
            Text("✓")
                .frame(width: 40, alignment: .center)
        }
        .font(BulkUpFont.badge())
        .tracking(0.5)
        .foregroundColor(BulkUpColors.textTertiary)

        // Set rows
        ForEach(0..<totalSetsCount, id: \.self) { setIndex in
            workoutSetRow(setIndex: setIndex)
        }

        // Add set button
        Button {
            workoutSession.addSet(day: normalizedDay, exerciseIndex: exercise.orderIndex)
            ensureArrayCapacity()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 12))
                Text("Anadir serie")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(BulkUpColors.accent)
            .padding(.vertical, Spacing.xs)
        }

        // Note input
        HStack(spacing: Spacing.sm) {
            Image(systemName: "note.text")
                .font(.system(size: 10))
                .foregroundColor(BulkUpColors.textTertiary)
            TextField("Notas...", text: $localNote)
                .font(.system(size: 12))
                .foregroundColor(BulkUpColors.textPrimary)
        }
    }

    @ViewBuilder
    private func workoutSetRow(setIndex: Int) -> some View {
        let isCompleted = workoutSession.isSetCompleted(
            day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIndex
        )
        let isFailed = workoutSession.isSetFailed(
            day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIndex
        )

        HStack(spacing: 0) {
            // Set number circle
            ZStack {
                Circle()
                    .fill(isCompleted ? BulkUpColors.accent : BulkUpColors.surfaceElevated)
                    .frame(width: 28, height: 28)
                Text("\(setIndex + 1)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isCompleted ? BulkUpColors.onAccent : BulkUpColors.textSecondary)
            }
            .frame(width: 40, alignment: .leading)

            // Weight input with steppers
            HStack(spacing: 0) {
                Button {
                    adjustWeight(setIndex: setIndex, delta: -2.5)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(BulkUpColors.textTertiary)
                        .frame(width: 18, height: 32)
                }

                TextField("—", text: weightBinding(for: setIndex))
                    .keyboardType(.decimalPad)
                    .focused($focusedSet, equals: setIndex)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .frame(width: 36, height: 32)
                    .disabled(isCompleted)

                Button {
                    adjustWeight(setIndex: setIndex, delta: 2.5)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(BulkUpColors.textTertiary)
                        .frame(width: 18, height: 32)
                }
            }
            .frame(width: 72, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCompleted ? BulkUpColors.accent.opacity(0.08) : BulkUpColors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isCompleted ? BulkUpColors.accent.opacity(0.3) : BulkUpColors.textTertiary.opacity(0.15),
                        lineWidth: 1
                    )
            )

            // Reps input with steppers
            HStack(spacing: 0) {
                Button {
                    adjustReps(setIndex: setIndex, delta: -1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(BulkUpColors.textTertiary)
                        .frame(width: 16, height: 32)
                }

                TextField(defaultReps, text: repsBinding(for: setIndex))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .frame(width: 24, height: 32)
                    .disabled(isCompleted)

                Button {
                    adjustReps(setIndex: setIndex, delta: 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(BulkUpColors.textTertiary)
                        .frame(width: 16, height: 32)
                }
            }
            .frame(width: 56, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCompleted ? BulkUpColors.accent.opacity(0.08) : BulkUpColors.surfaceElevated)
            )

            Spacer()

            // Failure toggle
            if isCompleted && isFailed {
                Button {
                    workoutSession.toggleFailure(
                        day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIndex
                    )
                } label: {
                    Text("F")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(BulkUpColors.onAccent)
                        .frame(width: 24, height: 24)
                        .background(BulkUpColors.warning)
                        .clipShape(Circle())
                }
            }

            // Check button
            Button {
                if isCompleted {
                    workoutSession.uncompleteSet(
                        day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIndex
                    )
                } else {
                    completeSetAndSave(setIndex: setIndex)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(isCompleted ? BulkUpColors.accent : BulkUpColors.surfaceElevated)
                        .frame(width: 32, height: 32)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(BulkUpColors.onAccent)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(
                            isCompleted ? BulkUpColors.accent : BulkUpColors.textTertiary.opacity(0.3),
                            lineWidth: 1.5
                        )
                )
            }
            .frame(width: 40, alignment: .center)
        }
        .padding(.vertical, 2)
        .background(
            isCompleted
                ? BulkUpColors.accent.opacity(0.04)
                : Color.clear
        )
        .cornerRadius(8)

        // Previous weight hint below completed set
        if !isCompleted, let prev = safeGetPrevWeight(setIndex), prev > 0 {
            HStack {
                Spacer()
                    .frame(width: 40)
                Text("anterior: \(formatWeight(prev)) kg")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(BulkUpColors.textTertiary)
                Spacer()
            }
        }
    }

    // MARK: - Normal Mode Content (unchanged)

    @ViewBuilder
    private var normalModeContent: some View {
        // Set-by-set table header
        HStack(spacing: 0) {
            Text("SERIE")
                .frame(width: 44, alignment: .leading)
            Text("PESO")
                .frame(width: 64, alignment: .center)
            Text("ANTERIOR")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(BulkUpFont.badge())
        .tracking(0.5)
        .foregroundColor(BulkUpColors.textTertiary)

        // Weight fields as rows
        ForEach(0..<exercise.sets, id: \.self) { setIndex in
            HStack(spacing: 0) {
                Text("S\(setIndex + 1)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .frame(width: 44, alignment: .leading)

                TextField("—", text: weightBinding(for: setIndex))
                    .keyboardType(.decimalPad)
                    .focused($focusedSet, equals: setIndex)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .frame(width: 64, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                hasWeight(setIndex)
                                    ? BulkUpColors.accent.opacity(0.08)
                                    : BulkUpColors.surfaceElevated
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                hasWeight(setIndex)
                                    ? BulkUpColors.accent.opacity(0.3)
                                    : BulkUpColors.textTertiary.opacity(0.15),
                                lineWidth: 1
                            )
                    )

                Spacer()

                if let prev = safeGetPrevWeight(setIndex), prev > 0 {
                    Text("ant. \(formatWeight(prev)) kg")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }
        }

        // Note input
        HStack(spacing: Spacing.sm) {
            Image(systemName: "note.text")
                .font(.system(size: 10))
                .foregroundColor(BulkUpColors.textTertiary)
            TextField("Notas...", text: $localNote)
                .font(.system(size: 12))
                .foregroundColor(BulkUpColors.textPrimary)
        }

        // Save row
        HStack(spacing: Spacing.md) {
            if hasPreviousWeights {
                Button {
                    fillFromPrevious()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text("Usar anterior")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(BulkUpColors.accent)
                }
            }

            Spacer()

            Button {
                focusedSet = nil
                saveWeights()
            } label: {
                HStack(spacing: Spacing.xs) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(BulkUpColors.accent)
                    } else if showSaved {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(BulkUpColors.success)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(BulkUpColors.accent)
                    }
                    Text(showSaved ? "Guardado" : "Guardar")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(showSaved ? BulkUpColors.success : BulkUpColors.accent)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    showSaved
                        ? BulkUpColors.success.opacity(0.1)
                        : BulkUpColors.accent.opacity(0.1)
                )
                .cornerRadius(CornerRadius.small)
            }
            .disabled(isSaving)
        }
    }

    // MARK: - Workout Mode Actions

    private func completeSetAndSave(setIndex: Int) {
        // Mark complete in session
        let nextSetIdx = setIndex + 1
        let nextInfo: String?
        if nextSetIdx < totalSetsCount {
            let weightStr = safeGetWeightText(nextSetIdx)
            let repsStr = safeGetRepsText(nextSetIdx)
            nextInfo = String(format: String(localized: "Serie %lld · %@kg × %@"), nextSetIdx + 1, weightStr, repsStr)
        } else {
            nextInfo = nil
        }

        workoutSession.completeSet(
            day: normalizedDay,
            exerciseIndex: exercise.orderIndex,
            setIndex: setIndex,
            restSeconds: exercise.restSeconds,
            nextInfo: nextInfo
        )

        // Update weight in training manager
        let weightValue = Double(safeGetWeightText(setIndex)) ?? 0
        if weightValue > 0 {
            trainingManager.updateWeight(
                day: normalizedDay,
                exerciseIndex: exercise.orderIndex,
                exerciseName: exercise.name,
                setIndex: setIndex,
                weight: weightValue
            )
        }

        // Store actual reps
        if let reps = Int(safeGetRepsText(setIndex)) {
            workoutSession.setActualReps(
                day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIndex, reps: reps
            )
        }

        // Auto-save to backend
        focusedSet = nil
        saveWeights()
    }

    private func safeGetWeightText(_ index: Int) -> String {
        guard index < weightTexts.count else { return "" }
        return weightTexts[index]
    }

    private func safeGetRepsText(_ index: Int) -> String {
        guard index < repsTexts.count else { return defaultReps }
        return repsTexts[index].isEmpty ? defaultReps : repsTexts[index]
    }

    private func adjustWeight(setIndex: Int, delta: Double) {
        ensureArrayCapacity()
        guard setIndex < weightTexts.count else { return }
        let current = Double(weightTexts[setIndex]) ?? (safeGetPrevWeight(setIndex) ?? 0)
        let newVal = max(0, current + delta)
        weightTexts[setIndex] = formatWeight(newVal)
        trainingManager.updateWeight(
            day: normalizedDay,
            exerciseIndex: exercise.orderIndex,
            exerciseName: exercise.name,
            setIndex: setIndex,
            weight: newVal
        )
    }

    private func adjustReps(setIndex: Int, delta: Int) {
        ensureArrayCapacity()
        guard setIndex < repsTexts.count else { return }
        let current = Int(repsTexts[setIndex]) ?? (Int(defaultReps) ?? 0)
        let newVal = max(0, current + delta)
        repsTexts[setIndex] = "\(newVal)"
    }

    private func repsBinding(for setIndex: Int) -> Binding<String> {
        Binding(
            get: {
                guard setIndex < repsTexts.count else { return "" }
                return repsTexts[setIndex]
            },
            set: { newValue in
                ensureArrayCapacity()
                guard setIndex < repsTexts.count else { return }
                repsTexts[setIndex] = newValue
            }
        )
    }

    private func ensureArrayCapacity() {
        while weightTexts.count < totalSetsCount {
            // Start empty — the previous week's weight is only a hint, never a
            // real value for this week (otherwise it looks registered every week).
            weightTexts.append("")
        }
        while repsTexts.count < totalSetsCount {
            repsTexts.append(defaultReps)
        }
    }

    // MARK: - Weight Data

    private func loadInitialData() {
        let setsCount = max(exercise.sets, totalSetsCount)
        weightTexts = (0..<setsCount).map { setIndex in
            let key = trainingManager.generateWeightKey(
                day: normalizedDay,
                exerciseIndex: exercise.orderIndex,
                exerciseName: exercise.name,
                setIndex: setIndex,
                weekStart: currentWeekString
            )
            if let w = trainingManager.weights[key], w > 0 {
                return formatWeight(w)
            }
            return ""
        }
        repsTexts = (0..<setsCount).map { _ in defaultReps }
        loadPreviousWeights()
        loadExerciseNote()
    }

    private func loadExerciseNote() {
        if let backendNote = trainingManager.backendExerciseNotes[exerciseKey] {
            localNote = backendNote
        } else {
            localNote = ""
        }
    }

    private func loadPreviousWeights() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        previousWeights = (0..<exercise.sets).map { setIndex in
            var checkWeek = trainingManager.selectedWeek
            for _ in 0..<4 {
                checkWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: checkWeek) ?? checkWeek
                let weekStr = df.string(from: trainingManager.getWeekStart(checkWeek))
                let key = trainingManager.generateWeightKey(
                    day: normalizedDay,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: exercise.name,
                    setIndex: setIndex,
                    weekStart: weekStr
                )
                if let w = trainingManager.weights[key], w > 0 {
                    return w
                }
            }
            return nil
        }
    }

    private var hasPreviousWeights: Bool {
        previousWeights.contains(where: { $0 != nil })
    }

    private func safeGetPrevWeight(_ index: Int) -> Double? {
        guard index < previousWeights.count else { return nil }
        return previousWeights[index]
    }

    private func hasWeight(_ setIndex: Int) -> Bool {
        guard setIndex < weightTexts.count else { return false }
        return Double(weightTexts[setIndex]) != nil && !weightTexts[setIndex].isEmpty
    }

    private func weightBinding(for setIndex: Int) -> Binding<String> {
        Binding(
            get: {
                guard setIndex < weightTexts.count else { return "" }
                return weightTexts[setIndex]
            },
            set: { newValue in
                guard setIndex < weightTexts.count else { return }
                weightTexts[setIndex] = newValue
                let weight = Double(newValue) ?? 0
                trainingManager.updateWeight(
                    day: normalizedDay,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: exercise.name,
                    setIndex: setIndex,
                    weight: weight
                )
            }
        )
    }

    private func fillFromPrevious() {
        for i in 0..<exercise.sets {
            if let prev = safeGetPrevWeight(i), prev > 0,
               i < weightTexts.count, weightTexts[i].isEmpty {
                weightTexts[i] = formatWeight(prev)
                trainingManager.updateWeight(
                    day: normalizedDay,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: exercise.name,
                    setIndex: i,
                    weight: prev
                )
            }
        }
    }

    private func saveWeights() {
        guard let user = authManager.user else { return }
        isSaving = true

        Task {
            await trainingManager.saveWeightsToDatabase(
                day: normalizedDay,
                exerciseIndex: exercise.orderIndex,
                exerciseName: exercise.name,
                note: localNote,
                userId: user.id
            )
            isSaving = false
            showSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSaved = false
            }
        }
    }

    private func formatWeight(_ w: Double) -> String {
        String(format: "%.1f", w).replacingOccurrences(of: ".0", with: "")
    }
}
