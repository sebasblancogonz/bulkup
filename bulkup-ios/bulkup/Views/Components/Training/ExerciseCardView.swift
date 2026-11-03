//
//  ExerciseCardView.swift
//  bulkup
//
//  Premium card-based exercise row with full name, structured sets, weight logging.
//  Supports workout session mode with per-set check-off, failure toggle, and rest timer.
//

import SwiftUI
import SwiftData
import PhotosUI
import AVKit

/// Shared column geometry for the set-logging table so the header and every row
/// stay aligned. Steppers are sized for comfortable tapping mid-workout.
private enum SetCol {
    static let gap: CGFloat = 8         // breathing room between SERIE / KG / REPS
    static let serie: CGFloat = 28      // set number column
    static let rowH: CGFloat = 44       // every control in the row is a 44pt target
    static let stepper: CGFloat = 36    // +/- tap target width — do not slim (accessibility)
    static let stepperIcon: CGFloat = 13
    static let kg: CGFloat = 118        // stepper + field(46, fits "102.5") + stepper
    static let reps: CGFloat = 100      // stepper + field(28, reps are 1-2 digits) + stepper
    static let check: CGFloat = 36
}

struct ExerciseCardView: View {
    let exercise: Exercise
    let exerciseIndex: Int
    let dayName: String
    let currentDate: Date
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    var onShowProgress: (() -> Void)? = nil

    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var workoutSession: WorkoutSessionManager = .shared
    @State private var showAlternatives = false

    private var normalizedDayName: String {
        dayName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
    }

    /// Plan name unless a session-only alternative was chosen for this slot.
    private var effectiveName: String {
        workoutSession.effectiveExerciseName(
            day: normalizedDayName, exerciseIndex: exercise.orderIndex, planName: exercise.name
        )
    }

    /// Sets for this exercise this week: the plan's count plus whatever the
    /// user added or removed today.
    private var totalSets: Int {
        trainingManager.effectiveSets(for: exercise, day: normalizedDayName)
    }

    private var completedSets: Int {
        trainingManager.getCompletedSets(
            day: normalizedDayName,
            exerciseIndex: exercise.orderIndex,
            exerciseName: effectiveName,
            totalSets: totalSets
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
            return workoutSession.isExerciseComplete(
                day: normalizedDayName,
                exerciseIndex: exercise.orderIndex,
                totalSets: totalSets
            )
        }
        return completedSets == totalSets && totalSets > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed row — always visible
            Button(action: {
                if !isSkipped { onToggleExpand() }
            }) {
                HStack(spacing: Spacing.md) {
                    // Done mark: sky square when every set is logged; count while in progress
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(
                                isSkipped ? BulkUpColors.line :
                                allSetsLogged ? BulkUpColors.complete : BulkUpColors.line,
                                lineWidth: 1.5
                            )
                            .frame(width: 28, height: 28)

                        if isSkipped {
                            Image(systemName: "forward.fill")
                                .font(.system(.caption2, weight: .bold))
                                .foregroundColor(BulkUpColors.textTertiary)
                        } else if allSetsLogged {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(BulkUpColors.complete)
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.system(.caption2, weight: .bold))
                                .foregroundColor(Color.onFill(BulkUpColors.complete))
                        } else if workoutSession.isActive {
                            let done = workoutSession.completedSetsCount(day: normalizedDayName, exerciseIndex: exercise.orderIndex, totalSets: totalSets)
                            if done > 0 {
                                Text("\(done)")
                                    .font(BulkUpFont.numeric(.caption, weight: .semibold))
                                    .foregroundColor(BulkUpColors.accentText)
                            }
                        } else if completedSets > 0 {
                            Text("\(completedSets)")
                                .font(BulkUpFont.numeric(.caption, weight: .semibold))
                                .foregroundColor(BulkUpColors.accentText)
                        }
                    }

                    // Exercise name + metadata
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: Spacing.xs) {
                            Text(effectiveName)
                                .font(BulkUpFont.cardTitle())
                                .foregroundColor(
                                    isSkipped ? BulkUpColors.textTertiary : BulkUpColors.textPrimary
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
                                    Text("\(exercise.restSeconds)s")
                                        .font(BulkUpFont.numeric(.caption))
                                        .foregroundColor(BulkUpColors.textSecondary)
                                    Text("descanso")
                                        .font(.system(.caption, weight: .medium))
                                        .foregroundColor(BulkUpColors.textSecondary)
                                }

                                if let tempo = exercise.tempo, !tempo.isEmpty {
                                    Text("·")
                                        .foregroundColor(BulkUpColors.textTertiary)
                                    Text(tempo)
                                        .font(BulkUpFont.numeric(.caption))
                                        .foregroundColor(BulkUpColors.textSecondary)
                                }
                            }

                            setRepsPills
                        }
                    }

                    Spacer()

                    if !isSkipped {
                        Image(systemName: "chevron.down")
                            .font(.system(.caption2, weight: .bold))
                            .foregroundColor(BulkUpColors.textSecondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                }
                .padding(Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // Context menu for skip/unskip during workout
            .contextMenu {
                if isSkipped {
                    Button {
                        workoutSession.unskipExercise(day: normalizedDayName, exerciseIndex: exercise.orderIndex)
                    } label: {
                        Label("Restaurar ejercicio", systemImage: "arrow.uturn.backward")
                    }
                } else {
                    if let onShowProgress {
                        Button(action: onShowProgress) {
                            Label("Ver progreso", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    }
                    if workoutSession.isActive {
                        Button {
                            showAlternatives = true
                        } label: {
                            Label("Cambiar ejercicio", systemImage: "arrow.triangle.2.circlepath")
                        }
                        Button(role: .destructive) {
                            workoutSession.skipExercise(day: normalizedDayName, exerciseIndex: exercise.orderIndex)
                        } label: {
                            Label("Omitir ejercicio", systemImage: "forward.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAlternatives) {
                ExerciseAlternativesSheet(currentName: effectiveName) { name in
                    workoutSession.overrideExercise(
                        day: normalizedDayName,
                        exerciseIndex: exercise.orderIndex,
                        name: name
                    )
                    // Push the swap into the shared store → watch + Live Activity.
                    workoutSession.syncStoreFromSession(trainingManager: trainingManager)
                }
                .presentationDetents([.medium, .large])
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

            // Secondary links: one quiet row (alternatives during a workout,
            // progress when the caller opts in). Both also live in the context menu.
            if isExpanded, !isSkipped, workoutSession.isActive || onShowProgress != nil {
                Divider()
                    .background(BulkUpColors.border)
                    .padding(.horizontal, Spacing.md)

                HStack(spacing: 0) {
                    if workoutSession.isActive {
                        cardLink("Alternativas", icon: "arrow.triangle.2.circlepath") { showAlternatives = true }
                    }
                    if workoutSession.isActive, onShowProgress != nil {
                        Rectangle().fill(BulkUpColors.line).frame(width: 1, height: 18)
                    }
                    if let onShowProgress {
                        cardLink("Ver progreso", icon: "chart.line.uptrend.xyaxis", action: onShowProgress)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xs)
            }
        }
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .lift()
        .opacity(isSkipped ? 0.6 : 1.0)
        .padding(.horizontal, Spacing.screenH)
    }

    private func cardLink(_ title: LocalizedStringKey, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(.caption, weight: .medium))
                Text(title)
                    .font(.system(.footnote, weight: .medium))
            }
            .foregroundColor(BulkUpColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm + 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                        .font(BulkUpFont.numeric(.caption, weight: .semibold))
                        .foregroundColor(isSetCompleted ? Color.onFill(BulkUpColors.complete) : BulkUpColors.textSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isSetCompleted ? BulkUpColors.complete : BulkUpColors.surfaceElevated)
                        )
                }
            } else {
                Text("\(totalSets)×\(exercise.reps)")
                    .font(BulkUpFont.numeric(.caption, weight: .semibold))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
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
    @State private var previousReps: [Int?] = []
    @State private var localNote: String = ""
    @State private var isSaving = false
    @State private var showSaved = false
    @FocusState private var focusedSet: Int?

    @State private var videoSets: Set<Int> = []          // set indices that have a video
    @State private var pendingVideoSet: Int?             // set awaiting a picker result
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var playerSet: Int?                   // set whose video is playing
    @AppStorage("hasSeenVideoStorageWarning") private var hasSeenVideoWarning = false
    @State private var showVideoWarning = false
    @State private var showVideoPicker = false
    /// Set awaiting "are you sure" before removal (it has logged data).
    @State private var pendingRemoveIndex: Int?

    private var normalizedDay: String {
        dayName.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }

    /// Plan name unless a session-only alternative was chosen for this slot.
    private var effectiveName: String {
        workoutSession.effectiveExerciseName(
            day: normalizedDay, exerciseIndex: exercise.orderIndex, planName: exercise.name
        )
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
            exerciseName: effectiveName,
            weekStart: currentWeekString
        )
    }

    private var isWorkoutMode: Bool {
        workoutSession.isActive
    }

    /// Plan sets plus this week's additions/removals (see TrainingManager).
    private var totalSetsCount: Int {
        trainingManager.effectiveSets(for: exercise, day: normalizedDay)
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
            } else if isWorkoutMode {
                // Non-weight exercise in active workout: show per-set completion rows
                VStack(spacing: 8) {
                    ForEach(0..<totalSetsCount, id: \.self) { setIndex in
                        HStack {
                            Text("Serie \(setIndex + 1)")
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.textPrimary)
                            Spacer()
                            completeButton(setIndex: setIndex)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                        .background(
                            workoutSession.isSetCompleted(
                                day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIndex
                            ) ? BulkUpColors.complete.opacity(0.08) : Color.clear
                        )
                        .cornerRadius(8)
                        .contextMenu { removeSetMenu(setIndex: setIndex) }
                    }
                    setCountControls
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
        .onChange(of: trainingManager.weights) { _, _ in
            // A set completed from the watch/widget writes trainingManager.weights
            // (via reconcileFromStore) but not this card's local weightTexts, so the
            // field would read empty until a full reload. Fill the empties in place.
            syncWeightTextsFromManager()
        }
        .onChange(of: trainingManager.setCountDeltas) { _, _ in
            // Sets added/removed here, in the recap or on another card for the
            // same slot: rebuild the rows from the (write-through) manager state.
            loadInitialData()
        }
        .confirmationDialog(
            "Eliminar serie",
            isPresented: Binding(
                get: { pendingRemoveIndex != nil },
                set: { if !$0 { pendingRemoveIndex = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingRemoveIndex
        ) { index in
            Button("Eliminar la serie \(index + 1)", role: .destructive) { removeSet(at: index) }
            Button("Cancelar", role: .cancel) {}
        } message: { _ in
            Text("Se borrarán el peso, las reps y el vídeo de esta serie.")
        }
        .photosPicker(
            isPresented: $showVideoPicker,
            selection: $selectedVideoItem,
            matching: .videos,
            photoLibrary: .shared()
        )
        .onChange(of: selectedVideoItem) { _, item in
            guard let item, let setIndex = pendingVideoSet else { return }
            Task {
                let picked = try? await item.loadTransferable(type: PickedVideo.self)
                if let picked {
                    WorkoutVideoStore.save(from: picked.url, for: videoKey(setIndex))
                }
                await MainActor.run {
                    refreshVideoSets()
                    selectedVideoItem = nil
                    pendingVideoSet = nil
                }
            }
        }
        .alert("Vídeos en este dispositivo", isPresented: $showVideoWarning) {
            Button("Entendido") {
                hasSeenVideoWarning = true
                showVideoPicker = true
            }
            Button("Cancelar", role: .cancel) { pendingVideoSet = nil }
        } message: {
            Text("Los vídeos se guardan solo en este dispositivo y no se suben a la nube.")
        }
        .sheet(item: Binding(
            get: { playerSet.map { VideoSheetItem(setIndex: $0) } },
            set: { playerSet = $0?.setIndex }
        )) { sheet in
            let setIndex = sheet.setIndex
            if let url = WorkoutVideoStore.url(for: videoKey(setIndex)) {
                SetVideoPlayerView(
                    url: url,
                    title: "Serie \(setIndex + 1)",
                    onReplace: { playerSet = nil; startVideoFlow(for: setIndex) },
                    onDelete: {
                        WorkoutVideoStore.delete(for: videoKey(setIndex))
                        refreshVideoSets()
                        playerSet = nil
                    }
                )
            } else {
                NavigationStack {
                    Text("Vídeo no disponible")
                        .foregroundColor(BulkUpColors.textSecondary)
                        .navigationTitle("Serie \(setIndex + 1)")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    // MARK: - Workout Mode Content

    @ViewBuilder
    private var workoutModeContent: some View {
        // Previous weights banner — tappable: copies last week's kg + reps in.
        if hasPreviousWeights {
            HStack {
                Text("En gris, lo de la última vez")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)

                Spacer()

                Button {
                    fillFromPrevious()
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(.caption2, weight: .semibold))
                        Text("Usar anterior")
                            .font(.system(.footnote, weight: .semibold))
                    }
                    .foregroundColor(BulkUpColors.textPrimary)
                }
            }
        }

        // Table header
        HStack(spacing: SetCol.gap) {
            Text("SERIE")
                .fixedSize()   // never truncate — may overflow slightly into the gap
                .frame(width: SetCol.serie, alignment: .leading)
            Text("KG")
                .frame(width: SetCol.kg, alignment: .center)
            Text("REPS")
                .frame(width: SetCol.reps, alignment: .center)
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(.caption2, weight: .semibold))
                .frame(width: SetCol.check, alignment: .center)
        }
        .font(.system(.caption2, weight: .semibold))
        .tracking(0.6)
        .foregroundColor(BulkUpColors.textTertiary)

        // Set rows
        ForEach(0..<totalSetsCount, id: \.self) { setIndex in
            workoutSetRow(setIndex: setIndex)
        }

        setCountControls

        // Note input
        HStack(spacing: Spacing.sm) {
            Image(systemName: "note.text")
                .font(.system(size: 10))
                .foregroundColor(BulkUpColors.textTertiary)
            TextField("Notas...", text: $localNote)
                .font(.system(.footnote))
                .foregroundColor(BulkUpColors.textPrimary)
        }
    }

    /// Shared check button used both in `workoutSetRow` (weight-tracking exercises)
    /// and in the non-weight per-set completion rows. Tapping toggles `completedSetIds`
    /// via the existing `completeSetAndSave` / `uncompleteSet` path.
    @ViewBuilder
    private func completeButton(setIndex: Int) -> some View {
        let isCompleted = workoutSession.isSetCompleted(
            day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIndex
        )
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
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(isCompleted ? BulkUpColors.complete
                          : (isNextSet(setIndex) ? BulkUpColors.accent.opacity(0.14) : BulkUpColors.surface))
                    .frame(width: 36, height: 36)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(.footnote, weight: .bold))
                        .foregroundColor(Color.onFill(BulkUpColors.complete))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .strokeBorder(
                        isCompleted ? BulkUpColors.complete
                            : (isNextSet(setIndex) ? BulkUpColors.accent : BulkUpColors.textTertiary.opacity(0.5)),
                        lineWidth: 1.5
                    )
            )
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .frame(width: SetCol.check, alignment: .center)
        .accessibilityLabel(isCompleted ? "Serie completada" : "Completar serie")
    }

    /// The first set not yet checked: the only pending check drawn in lime.
    private func isNextSet(_ setIndex: Int) -> Bool {
        (0..<totalSetsCount).first { !workoutSession.isSetCompleted(
            day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: $0) } == setIndex
    }

    @ViewBuilder
    private func workoutSetRow(setIndex: Int) -> some View {
        let isCompleted = workoutSession.isSetCompleted(
            day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIndex
        )
        let isFailed = workoutSession.isSetFailed(
            day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIndex
        )
        let isNext = isNextSet(setIndex)

        HStack(spacing: SetCol.gap) {
            // Set number
            Text("\(setIndex + 1)")
                .font(BulkUpFont.numeric(.subheadline, weight: .semibold))
                .foregroundColor(isCompleted ? BulkUpColors.complete
                                 : (isNext ? BulkUpColors.textPrimary : BulkUpColors.textTertiary))
                .frame(width: SetCol.serie, alignment: .leading)

            // Weight input with steppers
            HStack(spacing: 0) {
                Button {
                    adjustWeight(setIndex: setIndex, delta: -2.5)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: SetCol.stepperIcon, weight: .bold))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .frame(width: SetCol.stepper, height: SetCol.rowH)
                        .contentShape(Rectangle())
                }

                // Last session's kilos sit as the placeholder: visible, not logged.
                TextField(safeGetPrevWeight(setIndex).map { formatWeight($0) } ?? "—",
                          text: weightBinding(for: setIndex))
                    .keyboardType(.decimalPad)
                    .focused($focusedSet, equals: setIndex)
                    .multilineTextAlignment(.center)
                    .font(BulkUpFont.mono(16, weight: .semibold, relativeTo: .body))
                    .foregroundColor(isCompleted ? BulkUpColors.textSecondary : BulkUpColors.textPrimary)
                    .frame(width: SetCol.kg - SetCol.stepper * 2, height: SetCol.rowH)
                    .disabled(isCompleted)

                Button {
                    adjustWeight(setIndex: setIndex, delta: 2.5)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: SetCol.stepperIcon, weight: .bold))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .frame(width: SetCol.stepper, height: SetCol.rowH)
                        .contentShape(Rectangle())
                }
            }
            .frame(width: SetCol.kg, height: SetCol.rowH)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(isNext ? BulkUpColors.surface : BulkUpColors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .strokeBorder(fieldStroke(isCompleted: isCompleted, focused: focusedSet == setIndex), lineWidth: 1.5)
            )

            // Reps input with steppers
            HStack(spacing: 0) {
                Button {
                    adjustReps(setIndex: setIndex, delta: -1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: SetCol.stepperIcon, weight: .bold))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .frame(width: SetCol.stepper, height: SetCol.rowH)
                        .contentShape(Rectangle())
                }

                TextField(defaultReps, text: repsBinding(for: setIndex))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(BulkUpFont.mono(16, weight: .semibold, relativeTo: .body))
                    .foregroundColor(isCompleted ? BulkUpColors.textSecondary : BulkUpColors.textPrimary)
                    .frame(width: SetCol.reps - SetCol.stepper * 2, height: SetCol.rowH)
                    .disabled(isCompleted)

                Button {
                    adjustReps(setIndex: setIndex, delta: 1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: SetCol.stepperIcon, weight: .bold))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .frame(width: SetCol.stepper, height: SetCol.rowH)
                        .contentShape(Rectangle())
                }
            }
            .frame(width: SetCol.reps, height: SetCol.rowH)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .fill(isNext ? BulkUpColors.surface : BulkUpColors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                    .strokeBorder(fieldStroke(isCompleted: isCompleted, focused: focusedSet == setIndex), lineWidth: 1.5)
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
                        .foregroundColor(Color.onFill(BulkUpColors.warning))
                        .frame(width: 24, height: 24)
                        .background(BulkUpColors.warning)
                        .clipShape(Circle())
                }
            }

            // A video exists for this set (recording lives in the context menu)
            if videoSets.contains(setIndex) {
                Button { playerSet = setIndex } label: {
                    Image(systemName: "video.fill")
                        .font(.system(size: 13))
                        .foregroundColor(BulkUpColors.complete)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Ver vídeo de la serie \(setIndex + 1)")
            }

            // Check button (shared with non-weight per-set rows via completeButton helper)
            completeButton(setIndex: setIndex)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                .fill(isNext ? BulkUpColors.surfaceElevated : Color.clear)
        )
        .padding(.horizontal, -6)
        .opacity(isCompleted || isNext ? 1 : 0.72)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isNext)
        .contextMenu {
            videoMenu(setIndex: setIndex)
            removeSetMenu(setIndex: setIndex)
        }
    }

    /// Field border: sky when logged, lime while focused, nothing otherwise.
    private func fieldStroke(isCompleted: Bool, focused: Bool) -> Color {
        if isCompleted { return Color.clear }
        return focused ? BulkUpColors.accent : Color.clear
    }

    @ViewBuilder
    private func videoMenu(setIndex: Int) -> some View {
        if videoSets.contains(setIndex) {
            Button { playerSet = setIndex } label: {
                Label("Ver vídeo", systemImage: "video.fill")
            }
        } else {
            Button { startVideoFlow(for: setIndex) } label: {
                Label("Grabar vídeo de la serie", systemImage: "video.badge.plus")
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
            Text("KG")
                .frame(width: 64, alignment: .center)
            Text("REPS")
                .frame(width: 56, alignment: .center)
            Text("ANTERIOR")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(.caption2, weight: .semibold))
        .tracking(0.6)
        .foregroundColor(BulkUpColors.textTertiary)

        // Weight fields as rows: the first set without kilos steps forward.
        let firstEmpty = (0..<totalSetsCount).first { !hasWeight($0) }
        ForEach(0..<totalSetsCount, id: \.self) { setIndex in
            let isNext = setIndex == firstEmpty
            let logged = hasWeight(setIndex)
            HStack(spacing: 0) {
                Text("\(setIndex + 1)")
                    .font(BulkUpFont.numeric(.subheadline, weight: .semibold))
                    .foregroundColor(logged ? BulkUpColors.complete
                                     : (isNext ? BulkUpColors.textPrimary : BulkUpColors.textTertiary))
                    .frame(width: 44, alignment: .leading)

                TextField("—", text: weightBinding(for: setIndex))
                    .keyboardType(.decimalPad)
                    .focused($focusedSet, equals: setIndex)
                    .multilineTextAlignment(.center)
                    .font(BulkUpFont.mono(16, weight: .semibold, relativeTo: .body))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .frame(width: 64, height: SetCol.rowH)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .fill(isNext ? BulkUpColors.surface : BulkUpColors.surfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .strokeBorder(fieldStroke(isCompleted: false, focused: focusedSet == setIndex), lineWidth: 1.5)
                    )

                TextField(defaultReps, text: repsBinding(for: setIndex))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(BulkUpFont.mono(16, weight: .semibold, relativeTo: .body))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .frame(width: 48, height: SetCol.rowH)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                            .fill(isNext ? BulkUpColors.surface : BulkUpColors.surfaceElevated)
                    )
                    .frame(width: 56)

                Spacer()

                if let prev = safeGetPrevWeight(setIndex), prev > 0 {
                    Text(previousLabel(setIndex: setIndex, weight: prev))
                        .font(BulkUpFont.numeric(.caption))
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                if WorkoutVideoStore.hasVideo(for: videoKey(setIndex)) {
                    Button { playerSet = setIndex } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(.title3))
                            .foregroundColor(BulkUpColors.complete)
                    }
                    .accessibilityLabel("Ver vídeo de la serie \(setIndex + 1)")
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(isNext ? BulkUpColors.surfaceElevated : Color.clear)
            )
            .padding(.horizontal, -6)
            .contextMenu {
                videoMenu(setIndex: setIndex)
                removeSetMenu(setIndex: setIndex)
            }
        }

        setCountControls

        // Note input
        HStack(spacing: Spacing.sm) {
            Image(systemName: "note.text")
                .font(.system(size: 10))
                .foregroundColor(BulkUpColors.textTertiary)
            TextField("Notas...", text: $localNote)
                .font(.system(.footnote))
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
                            .font(.system(.footnote, weight: .medium))
                    }
                    .foregroundColor(BulkUpColors.textPrimary)
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
                            .foregroundColor(BulkUpColors.accentText)
                    }
                    Text(showSaved ? "Guardado" : "Guardar")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(showSaved ? BulkUpColors.success : BulkUpColors.accentText)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(BulkUpColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .disabled(isSaving)
        }
    }

    // MARK: - Workout Mode Actions

    private func completeSetAndSave(setIndex: Int) {
        // Block completing a weight-tracking set with no weight entered.
        // Non-weight exercises (weightTracking == false) skip this guard.
        var weightValue = Double(safeGetWeightText(setIndex)) ?? 0
        if weightValue <= 0 {
            // The weight may have been logged from the watch/widget: reconcile writes
            // trainingManager.weights, not this view's local text state.
            let key = trainingManager.generateWeightKey(
                day: normalizedDay,
                exerciseIndex: exercise.orderIndex,
                exerciseName: effectiveName,
                setIndex: setIndex
            )
            weightValue = trainingManager.weights[key] ?? 0
            if weightValue > 0, setIndex < weightTexts.count {
                weightTexts[setIndex] = Self.rawWeightString(weightValue)
            }
        }
        guard !exercise.weightTracking || weightValue > 0 else {
            focusedSet = setIndex
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        // Mark complete in session
        let nextSetIdx = setIndex + 1
        let nextInfo: String?
        if nextSetIdx < totalSetsCount {
            // Typed kilos first, last session's otherwise; never an empty slot.
            let typed = Double(safeGetWeightText(nextSetIdx)) ?? 0
            let kilos = typed > 0 ? typed : (safeGetPrevWeight(nextSetIdx) ?? 0)
            let weightStr = kilos > 0 ? formatWeight(kilos) : "—"
            let repsStr = safeGetRepsText(nextSetIdx)
            nextInfo = String(format: NSLocalizedString("Serie %lld · %@ kg × %@", comment: ""), nextSetIdx + 1, weightStr, repsStr)
        } else {
            nextInfo = nil
        }

        // Write weight + reps BEFORE completing: completeSet mirrors the set
        // into the shared store (watch / Live Activity) reading these values.
        if weightValue > 0 {
            trainingManager.updateWeight(
                day: normalizedDay,
                exerciseIndex: exercise.orderIndex,
                exerciseName: effectiveName,
                setIndex: setIndex,
                weight: weightValue
            )
        }
        if let reps = Int(safeGetRepsText(setIndex)) {
            workoutSession.setActualReps(
                day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIndex, reps: reps
            )
        }

        workoutSession.completeSet(
            day: normalizedDay,
            exerciseIndex: exercise.orderIndex,
            setIndex: setIndex,
            restSeconds: exercise.restSeconds,
            nextInfo: nextInfo
        )
        // Persist the reps the user actually saw: setReps was only written on
        // manual edits, so accepted prefills saved reps=0 for comma-format plans
        // and "Usar anterior" had no reps to reuse the following week.
        persistReps(setIndex: setIndex, text: safeGetRepsText(setIndex))

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
        weightTexts[setIndex] = Self.rawWeightString(newVal)
        trainingManager.updateWeight(
            day: normalizedDay,
            exerciseIndex: exercise.orderIndex,
            exerciseName: effectiveName,
            setIndex: setIndex,
            weight: newVal
        )
        workoutSession.syncStoreFromSession(trainingManager: trainingManager)
    }

    private func adjustReps(setIndex: Int, delta: Int) {
        ensureArrayCapacity()
        guard setIndex < repsTexts.count else { return }
        let current = Int(repsTexts[setIndex]) ?? (Int(defaultReps) ?? 0)
        let newVal = max(0, current + delta)
        repsTexts[setIndex] = "\(newVal)"
        persistReps(setIndex: setIndex, text: repsTexts[setIndex])
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
                persistReps(setIndex: setIndex, text: newValue)
            }
        )
    }

    /// Keep logged reps in the manager so they're saved with the weights and
    /// can be reused next week.
    private func persistReps(setIndex: Int, text: String) {
        trainingManager.updateReps(
            day: normalizedDay,
            exerciseIndex: exercise.orderIndex,
            exerciseName: effectiveName,
            setIndex: setIndex,
            reps: Int(text) ?? 0
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

    // MARK: - Add / remove sets (this week only; the plan is untouched)

    /// "Añadir serie" / "Quitar serie" row shared by both modes. Quitar drops
    /// the last set and confirms when it already has data; any set can also be
    /// removed from its long-press menu.
    private var setCountControls: some View {
        HStack(spacing: Spacing.md) {
            Button(action: addSet) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus.circle")
                        .font(.system(.footnote, weight: .semibold))
                    Text("Añadir serie")
                        .font(.system(.footnote, weight: .semibold))
                }
                .foregroundColor(BulkUpColors.textPrimary)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if totalSetsCount > 1 {
                Button {
                    requestRemoveSet(at: totalSetsCount - 1)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "minus.circle")
                            .font(.system(.footnote, weight: .semibold))
                        Text("Quitar serie")
                            .font(.system(.footnote, weight: .semibold))
                    }
                    .foregroundColor(BulkUpColors.textSecondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if totalSetsCount != exercise.sets {
                Text("Plan: \(exercise.sets)")
                    .font(BulkUpFont.numeric(.caption2, weight: .medium))
                    .foregroundColor(BulkUpColors.textTertiary)
            }
        }
    }

    @ViewBuilder
    private func removeSetMenu(setIndex: Int) -> some View {
        if totalSetsCount > 1 {
            Button(role: .destructive) {
                requestRemoveSet(at: setIndex)
            } label: {
                Label("Eliminar serie", systemImage: "trash")
            }
        }
    }

    private func setHasData(_ setIndex: Int) -> Bool {
        (Double(safeGetWeightText(setIndex)) ?? 0) > 0
            || workoutSession.isSetCompleted(day: normalizedDay, exerciseIndex: exercise.orderIndex, setIndex: setIndex)
            || videoSets.contains(setIndex)
    }

    private func requestRemoveSet(at setIndex: Int) {
        if setHasData(setIndex) {
            pendingRemoveIndex = setIndex
        } else {
            removeSet(at: setIndex)
        }
    }

    private func addSet() {
        workoutSession.addSet(
            day: normalizedDay, exerciseIndex: exercise.orderIndex,
            plannedSets: exercise.sets, trainingManager: trainingManager
        )
        // onChange(setCountDeltas) reloads the rows; keep arrays safe meanwhile.
        ensureArrayCapacity()
    }

    private func removeSet(at setIndex: Int) {
        focusedSet = nil
        workoutSession.removeSet(
            day: normalizedDay, exerciseIndex: exercise.orderIndex, exerciseName: effectiveName,
            plannedSets: exercise.sets, setIndex: setIndex, trainingManager: trainingManager
        )
        loadInitialData()
        // Persist the shorter set list so the backend record matches.
        saveWeights()
    }

    // MARK: - Video Helpers

    private func videoKey(_ setIndex: Int) -> String {
        trainingManager.generateWeightKey(
            day: normalizedDay, exerciseIndex: exercise.orderIndex,
            exerciseName: effectiveName, setIndex: setIndex, weekStart: currentWeekString
        )
    }

    private func refreshVideoSets() {
        videoSets = Set((0..<totalSetsCount).filter { WorkoutVideoStore.hasVideo(for: videoKey($0)) })
    }

    private func startVideoFlow(for setIndex: Int) {
        pendingVideoSet = setIndex
        if hasSeenVideoWarning {
            showVideoPicker = true
        } else {
            showVideoWarning = true
        }
    }

    // MARK: - Weight Data

    private func loadInitialData() {
        let setsCount = totalSetsCount
        weightTexts = (0..<setsCount).map { setIndex in
            let key = trainingManager.generateWeightKey(
                day: normalizedDay,
                exerciseIndex: exercise.orderIndex,
                exerciseName: effectiveName,
                setIndex: setIndex,
                weekStart: currentWeekString
            )
            if let w = trainingManager.weights[key], w > 0 {
                return Self.rawWeightString(w)
            }
            return ""
        }
        let planReps = Self.perSetReps(from: exercise.reps, count: setsCount, fallback: defaultReps)
        let loggedReps: [Int?] = (0..<setsCount).map { setIndex in
            let key = trainingManager.generateWeightKey(
                day: normalizedDay,
                exerciseIndex: exercise.orderIndex,
                exerciseName: effectiveName,
                setIndex: setIndex,
                weekStart: currentWeekString
            )
            return trainingManager.setReps[key]
        }
        repsTexts = Self.mergingLoggedReps(planReps, from: loggedReps)
        loadPreviousWeights()
        loadExerciseNote()
        refreshVideoSets()
    }

    /// Refresh weight fields from persisted weights without a full reload, filling
    /// only empty fields so it never overwrites in-progress typing or a field the
    /// user just cleared. Picks up weights logged from the watch/widget mid-session.
    private func syncWeightTextsFromManager() {
        ensureArrayCapacity()
        let stored: [Double?] = (0..<weightTexts.count).map { setIndex in
            let key = trainingManager.generateWeightKey(
                day: normalizedDay,
                exerciseIndex: exercise.orderIndex,
                exerciseName: effectiveName,
                setIndex: setIndex,
                weekStart: currentWeekString
            )
            return trainingManager.weights[key]
        }
        let merged = Self.mergingEmptyWeights(weightTexts, from: stored)
        if merged != weightTexts { weightTexts = merged }
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

        // One backwards scan per set: the first week with a logged weight also
        // supplies that set's reps, so weight and reps always come from the
        // same session instead of two different weeks.
        let found: [(Double, Int?)?] = (0..<totalSetsCount).map { setIndex in
            var checkWeek = trainingManager.selectedWeek
            for _ in 0..<4 {
                checkWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: checkWeek) ?? checkWeek
                let weekStr = df.string(from: trainingManager.getWeekStart(checkWeek))
                let key = trainingManager.generateWeightKey(
                    day: normalizedDay,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: effectiveName,
                    setIndex: setIndex,
                    weekStart: weekStr
                )
                if let w = trainingManager.weights[key], w > 0 {
                    return (w, trainingManager.setReps[key])
                }
                // Cross-plan fallback: a previous plan stored this exercise under
                // a different planId/day/orderIndex, so the exact key misses;
                // the name-keyed mirror still finds it.
                let nameKey = TrainingManager.nameKey(
                    exerciseName: effectiveName, setIndex: setIndex, weekStart: weekStr)
                if let w = trainingManager.weightsByName[nameKey], w > 0 {
                    return (w, trainingManager.repsByName[nameKey])
                }
            }
            return nil
        }
        previousWeights = found.map { $0?.0 }
        previousReps = found.map { $0?.1 }
    }

    private var hasPreviousWeights: Bool {
        previousWeights.contains(where: { $0 != nil })
    }

    /// "ant. 60 kg × 10" when last session's reps are known, "ant. 60 kg" otherwise.
    private func previousLabel(setIndex: Int, weight: Double) -> String {
        let base = "ant. \(formatWeight(weight)) kg"
        guard setIndex < previousReps.count, let reps = previousReps[setIndex], reps > 0 else {
            return base
        }
        return "\(base) × \(reps)"
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
                // Shown with the locale's separator; stored with "." (see set).
                return weightTexts[setIndex].replacingOccurrences(of: ".", with: Locale.current.decimalSeparator ?? ".")
            },
            set: { newValue in
                guard setIndex < weightTexts.count else { return }
                // The decimal pad shows the locale separator (a comma in es),
                // but Double(_:) only parses ".". Accept the comma and store a
                // period so the value parses and the field stays consistent.
                var normalized = newValue.replacingOccurrences(of: ",", with: ".")
                if let sep = Locale.current.decimalSeparator, sep != "." {
                    normalized = normalized.replacingOccurrences(of: sep, with: ".")
                }
                weightTexts[setIndex] = normalized
                let weight = Double(normalized) ?? 0
                trainingManager.updateWeight(
                    day: normalizedDay,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: effectiveName,
                    setIndex: setIndex,
                    weight: weight
                )
                // Mirror typed weights into the shared store so the watch/widget
                // see them (their completion guard reads the store's weight).
                workoutSession.syncStoreFromSession(trainingManager: trainingManager)
            }
        )
    }

    private func fillFromPrevious() {
        ensureArrayCapacity()
        for i in 0..<totalSetsCount {
            if let prev = safeGetPrevWeight(i), prev > 0,
               i < weightTexts.count, weightTexts[i].isEmpty {
                weightTexts[i] = Self.rawWeightString(prev)
                trainingManager.updateWeight(
                    day: normalizedDay,
                    exerciseIndex: exercise.orderIndex,
                    exerciseName: effectiveName,
                    setIndex: i,
                    weight: prev
                )
            }
            // Reps always take the previous value: tapping the button is an
            // explicit "repeat last week", and the field is never empty
            // (it's pre-filled from the plan) so an emptiness check never fires.
            if i < previousReps.count, let prevReps = previousReps[i], prevReps > 0,
               i < repsTexts.count {
                repsTexts[i] = "\(prevReps)"
                persistReps(setIndex: i, text: repsTexts[i])
            }
        }
        workoutSession.syncStoreFromSession(trainingManager: trainingManager)
    }

    private func saveWeights() {
        guard let user = authManager.user else { return }
        isSaving = true

        Task {
            await trainingManager.saveWeightsToDatabase(
                day: normalizedDay,
                exerciseIndex: exercise.orderIndex,
                exerciseName: effectiveName,
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

    private func formatWeight(_ w: Double) -> String { Self.formatWeightString(w) }

    private static let displayWeightFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = false
        return f
    }()

    /// Kilos for the eye: the locale's decimal separator ("62,5" in es).
    static func formatWeightString(_ w: Double) -> String {
        displayWeightFormatter.string(from: NSNumber(value: w)) ?? rawWeightString(w)
    }

    private static let rawWeightFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = false
        return f
    }()

    /// Kilos for the model: always "." so `Double(_:)` parses it back.
    static func rawWeightString(_ w: Double) -> String {
        rawWeightFormatter.string(from: NSNumber(value: w)) ?? String(format: "%.2f", w)
    }

    /// Reps actually logged for this week win over the plan's prescription;
    /// absent or zero logged reps fall back to the plan.
    static func mergingLoggedReps(_ planned: [String], from logged: [Int?]) -> [String] {
        zip(planned, logged).map { plan, reps in
            guard let r = reps, r > 0 else { return plan }
            return "\(r)"
        }
    }

    /// Fill empty weight fields from persisted weights; leave non-empty fields and
    /// zero/absent weights untouched. Pure so the watch-sync path stays testable.
    static func mergingEmptyWeights(_ texts: [String], from stored: [Double?]) -> [String] {
        zip(texts, stored).map { text, weight in
            guard text.isEmpty, let w = weight, w > 0 else { return text }
            return rawWeightString(w)
        }
    }

    // MARK: - Video Player Sheet

    private struct VideoSheetItem: Identifiable { let setIndex: Int; var id: Int { setIndex } }

    private struct SetVideoPlayerView: View {
        let url: URL
        let title: String
        let onReplace: () -> Void
        let onDelete: () -> Void
        @State private var player: AVPlayer?

        var body: some View {
            NavigationStack {
                Group {
                    if let player {
                        VideoPlayer(player: player).ignoresSafeArea(edges: .bottom)
                    } else {
                        Color.black
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Reemplazar") { onReplace() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Eliminar", role: .destructive) { onDelete() }
                    }
                }
            }
            .onAppear { if player == nil { player = AVPlayer(url: url) } }
        }
    }
}

extension ExerciseWeightLogger {
    /// Per-set rep targets parsed from `exercise.reps`. Mirrors the comma-splitting
    /// `setRepsPills` already uses (ExerciseCardView.swift:215-217). A range like
    /// "8-12" resolves to its upper bound; a single value repeats for every set.
    static func perSetReps(from reps: String, count: Int, fallback: String) -> [String] {
        guard count > 0 else { return [] }
        var parts = reps.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        // "8-12-10" (3+ dashed numbers, no commas) is a per-set list, not a
        // range; exactly two ("8-12") keeps meaning a range. Same rule as
        // TrainingManager.plannedReps so fields and saves agree.
        if parts.count == 1 {
            let dashed = parts[0].split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            if dashed.count >= 3, dashed.allSatisfy({ Int($0) != nil }) { parts = dashed }
        }
        func upperBound(_ s: String) -> String {
            s.contains("-") ? (s.split(separator: "-").last.map(String.init) ?? s) : s
        }
        if parts.count > 1 {
            return (0..<count).map { i in i < parts.count ? upperBound(parts[i]) : fallback }
        }
        return Array(repeating: fallback, count: count)
    }

    #if DEBUG
    static func runSelfCheck() {
        assert(perSetReps(from: "10, 8, 6", count: 3, fallback: "10") == ["10", "8", "6"])
        assert(perSetReps(from: "10, 8, 6", count: 4, fallback: "10") == ["10", "8", "6", "10"])
        assert(perSetReps(from: "8-12", count: 3, fallback: "12") == ["12", "12", "12"])
        assert(perSetReps(from: "12", count: 2, fallback: "12") == ["12", "12"])
        assert(perSetReps(from: "12, 10-8", count: 2, fallback: "12") == ["12", "8"])
        assert(perSetReps(from: "8-12-10", count: 3, fallback: "10") == ["8", "12", "10"])
        assert(perSetReps(from: "8-12-10", count: 4, fallback: "10") == ["8", "12", "10", "10"])
        assert(perSetReps(from: "8-12", count: 2, fallback: "12") == ["12", "12"],
               "two dashed numbers stays a range")

        // Watch/widget completes a set → weight lands in trainingManager.weights but
        // this card's empty text field must adopt it, without touching typed/cleared ones.
        assert(mergingEmptyWeights(["", "80", ""], from: [50, 60, nil]) == ["50", "80", ""],
               "fills empty from stored, keeps typed value, leaves empty when nothing stored")
        assert(mergingEmptyWeights([""], from: [0]) == [""], "a zero weight never fills a field")
        assert(mergingEmptyWeights(["70"], from: [50]) == ["70"], "never overwrites an existing value")

        // Reps logged last session must reappear instead of the plan's prescription.
        assert(mergingLoggedReps(["12", "12", "12"], from: [10, nil, 0]) == ["10", "12", "12"],
               "logged reps win; nil and zero fall back to the plan")
    }
    #endif
}
