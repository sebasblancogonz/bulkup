import SwiftData
import SwiftUI

struct TrainingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var trainingManager: TrainingManager
    @ObservedObject private var friendsManager = FriendsManager.shared
    @ObservedObject private var workoutSession = WorkoutSessionManager.shared
    @AppStorage("trainingViewMode") private var viewMode: ViewMode = .day
    @State private var selectedDay = ""
    @State private var expandedDay: Int? = nil
    @State private var expandedExercises: Set<String> = []
    @State private var showFinishConfirm = false
    @State private var currentDayIndex = 0

    // Date navigation
    @State private var currentDate: Date = Date()

    // Exercise progress navigation
    @State private var progressExercise: ProgressExerciseSelection? = nil

    // Workout completion prompt
    @State private var showingCompletionPrompt = false
    @State private var completionExerciseCount = 0
    @State private var completionTotalSets = 0
    @State private var showFeedback = false
    @State private var feedbackDayName = ""
    // Item-driven (not isPresented+String) so the sheet content is always built
    // with the tapped day — the isPresented variant can present with the stale
    // previous value and render an empty (blank) sheet.
    private struct RecapSelection: Identifiable {
        let day: String
        var id: String { day }
    }
    @State private var recapSelection: RecapSelection?
    @AppStorage("lastCompletionPromptDate") private var lastCompletionPromptDate: String = ""

    enum ViewMode: String, CaseIterable {
        case week = "week"
        case day = "day"

        var displayName: LocalizedStringKey {
            switch self {
            case .week: return "Semanal"
            case .day: return "Diario"
            }
        }

        var icon: String {
            switch self {
            case .week: return "calendar"
            case .day: return "calendar.day.timeline.left"
            }
        }
    }

    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        // Produces the weekday name matched against the plan's Spanish day data
        // (getTrainingDayForDate). Must stay Spanish, not the app/display locale —
        // otherwise "monday" never matches "lunes" and every day reads as rest.
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE"
        f.calendar = Calendar(identifier: .gregorian)
        f.calendar?.firstWeekday = 2
        return f
    }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = LanguageManager.shared.locale
        cal.firstWeekday = 2
        return cal
    }

    private func getTrainingDayForDate(_ date: Date) -> String? {
        let dayName = dayFormatter.string(from: date).lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        return trainingManager.trainingData.first { trainingDay in
            let normalized = trainingDay.day.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            return normalized == dayName || normalized.contains(dayName)
        }?.day
    }

    private var currentTrainingDay: String? {
        return getTrainingDayForDate(currentDate)
    }

    private var compactDateLabel: String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.locale
        f.dateFormat = "EEEE d MMM"
        return f.string(from: currentDate).lowercased()
    }

    private var weekRangeLabel: LocalizedStringKey {
        let start = trainingManager.getWeekStart(trainingManager.selectedWeek)
        let f = DateFormatter()
        f.locale = LanguageManager.shared.locale
        f.dateFormat = "d MMM"
        return "Semana del \(f.string(from: start))"
    }

    private func exerciseRowId(_ exercise: Exercise, day: String) -> String {
        "\(day)-\(exercise.orderIndex)-\(exercise.name)"
    }

    private func loggedExerciseCount(for dayData: TrainingDay) -> Int {
        let normalizedDay = dayData.day.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        return dayData.exercises.filter { ex in
            trainingManager.getCompletedSets(
                day: normalizedDay,
                exerciseIndex: ex.orderIndex,
                exerciseName: ex.name,
                totalSets: trainingManager.effectiveSets(for: ex, day: normalizedDay)
            ) > 0
        }.count
    }

    /// A day is done when the user finished a session for it (backend sessions
    /// from any device, or the local mark written on save) or, for days logged
    /// without a session, when every exercise has at least one set with weight.
    ///
    /// Checking only logged sets was wrong: skipped exercises and 0 kg
    /// (bodyweight) sets never count, so a finished workout kept showing
    /// "Continuar Entreno".
    private func isDayCompleted(_ dayData: TrainingDay) -> Bool {
        if trainingManager.isDayCompleted(day: dayData.day) {
            return true
        }
        let logged = loggedExerciseCount(for: dayData)
        return logged == dayData.exercises.count && dayData.exercises.count > 0
    }

    /// Weekday index (Mon=0...Sun=6) for current date
    private var currentWeekdayIndex: Int {
        let weekday = calendar.component(.weekday, from: currentDate)
        return (weekday + 5) % 7
    }

    /// Localized single-letter weekday symbols, Monday-first
    private var weekDayLetters: [String] {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.locale
        let symbols = f.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        return Array(symbols[1...]) + [symbols[0]]
    }

    /// Which day indices have a workout assigned
    private var workoutDayIndices: Set<Int> {
        let spanishDayOrder: [String: Int] = [
            "lunes": 0, "martes": 1, "miercoles": 2, "jueves": 3,
            "viernes": 4, "sabado": 5, "domingo": 6,
        ]
        var indices = Set<Int>()
        for day in trainingManager.trainingData {
            let norm = day.day.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            if let idx = spanishDayOrder[norm] {
                indices.insert(idx)
            }
        }
        return indices
    }

    var body: some View {
        Group {
            if trainingManager.isLoading {
                loadingView
            } else if trainingManager.trainingData.isEmpty {
                emptyStateView
            } else if !trainingManager.isFullyLoaded {
                dataLoadedButWeightsLoadingView
            } else {
                mainContentView
            }
        }
        .onAppear {
            if trainingManager.trainingData.isEmpty
                && !trainingManager.isLoading
            {
                Task {
                    if let user = authManager.user {
                        await trainingManager.loadTrainingDataForTab(
                            userId: user.id
                        )
                    }
                }
            }

            if selectedDay.isEmpty && !trainingManager.trainingData.isEmpty {
                selectedDay = trainingManager.trainingData[0].day
                currentDayIndex = 0
            }

            syncToActiveSessionDay()

            Task {
                await friendsManager.loadTodayStatus()
            }
            #if DEBUG
            if DesignPreview.isActive { expandFirstIncomplete() }
            #endif
            consumePendingExercise()
        }
        // A session restored after process death keeps its own day (e.g. the user
        // was doing yesterday's workout). currentDate resets to today on relaunch,
        // so without this the UI renders today's plan against a session keyed to
        // another day.
        .onChange(of: workoutSession.isActive) { _, isActive in
            if isActive { syncToActiveSessionDay() }
        }
        .refreshable {
            if let user = authManager.user {
                await trainingManager.loadActiveTrainingPlan(userId: user.id)
            }
        }
        .onChange(of: trainingManager.selectedWeek) { _, newWeek in
            Task {
                await trainingManager.loadWeightsForWeek(newWeek)
            }
        }
        // Day/strip navigation moves `currentDate`; the weights + completion are
        // scoped to `selectedWeek`. Without this sync, browsing to another week
        // kept showing the original week's weights (and its "anterior" history).
        .onChange(of: currentDate) { _, newDate in
            let newWeek = trainingManager.getWeekStart(newDate)
            if newWeek != trainingManager.getWeekStart(trainingManager.selectedWeek) {
                trainingManager.selectedWeek = newWeek
            }
        }
        .onChange(of: trainingManager.trainingData) { _, _ in
            expandedDay = nil
            expandedExercises.removeAll()
        }
        .numbersOnlyKeyboardWithDone()
        .onChange(of: trainingManager.savedWeights) { _, _ in
            checkWorkoutCompletion()
        }
        .sheet(isPresented: $showingCompletionPrompt) {
            WorkoutCompletionSheet(
                exerciseCount: completionExerciseCount,
                totalSets: completionTotalSets,
                onConfirm: {
                    markWorkoutComplete()
                },
                onDismiss: {
                    showingCompletionPrompt = false
                }
            )
            .presentationDetents([.medium])
        }
        // Rest timer sheet. Bound to restSheetVisible (not restTimerActive) so a
        // swipe-down hides only the sheet — the countdown continues in the banner.
        .sheet(isPresented: $workoutSession.restSheetVisible) {
            RestTimerSheet(session: workoutSession)
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(false)
        }
        // Listen for finish from FAB menu
        .onReceive(
            NotificationCenter.default.publisher(for: .finishWorkoutSession)
        ) { _ in
            if workoutSession.isActive {
                finishWorkoutSession()
            }
        }
        // Hoy asks for a specific exercise card: consume the intent whenever it
        // changes while on screen, and on appear for a cold tab.
        .onReceive(trainingManager.$pendingExerciseToOpen) { _ in
            consumePendingExercise()
        }
        // Exercise progress navigation (driven by the visible "Ver progreso" button in ExerciseCardView)
        .navigationDestination(item: $progressExercise) { selection in
            ExerciseProgressView(
                exerciseName: selection.name,
                exerciseIndex: selection.orderIndex,
                weightTracking: selection.weightTracking
            )
        }
    }

    // MARK: - Workout Completion

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }

    private func checkWorkoutCompletion() {
        guard !workoutSession.isActive else { return } // Don't show during session
        guard calendar.isDateInToday(currentDate) else { return }
        guard lastCompletionPromptDate != todayDateString else { return }
        guard !friendsManager.todayCompleted else { return }
        guard let trainingDay = currentTrainingDay else { return }

        let status = trainingManager.getDayCompletionStatus(dayName: trainingDay)
        guard status.allComplete else { return }

        completionExerciseCount = status.exerciseCount
        completionTotalSets = status.totalSetsCompleted
        lastCompletionPromptDate = todayDateString

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showingCompletionPrompt = true
        }
    }

    private func markWorkoutComplete() {
        guard let userId = authManager.user?.id else { return }

        // Persist the completed day so the Workouts ring counts it even when
        // no weight was logged (pure-bodyweight days). Prefer the session's own
        // day: the user may have browsed to another date before saving.
        let completedDay = workoutSession.currentDayName ?? currentTrainingDay
        if let dayName = completedDay {
            trainingManager.markDayCompleted(day: dayName)
        }

        Task {
            await friendsManager.toggleTodayCompletion(
                userId: userId,
                planId: trainingManager.trainingPlanId,
                dayName: completedDay
            )

            await MainActor.run {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                showingCompletionPrompt = false
            }
        }
    }

    // MARK: - Loading / Empty States

    private var dataLoadedButWeightsLoadingView: some View {
        VStack(spacing: Spacing.xl) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(BulkUpColors.accent)

            VStack(spacing: Spacing.sm) {
                Text("Cargando historial de pesos...")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("Tu rutina esta lista, preparando el progreso")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.xl) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(BulkUpColors.accent)

            VStack(spacing: Spacing.sm) {
                Text("Cargando tu rutina...")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("Preparando ejercicios y pesos...")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "dumbbell.fill",
            title: "Hora de entrenar!",
            subtitle: "Sube tu plan de entrenamiento y comienza a registrar tu progreso",
            color: BulkUpColors.accent,
            actionTitle: "Subir Plan de Entrenamiento",
            actionIcon: "plus.circle.fill",
            action: {
                NotificationCenter.default.post(name: .navigateToTrainingLibrary, object: nil)
            }
        )
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        ZStack {
            // Main scroll content
            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Navigation header — swap when session active
                        if workoutSession.isActive {
                            ActiveWorkoutHeader(
                                session: workoutSession,
                                onFinish: { finishWorkoutSession() },
                                onDiscard: { workoutSession.discardWorkout() }
                            )
                            .padding(.top, Spacing.sm)
                            .padding(.bottom, Spacing.lg)
                        } else {
                            navigationHeader
                                .padding(.horizontal, Spacing.screenH)
                                .padding(.top, Spacing.sm)
                                .padding(.bottom, Spacing.lg)
                        }

                        // Content
                        if viewMode == .week {
                            weekView
                        } else {
                            dayView
                        }

                        // Bottom spacer for CTA + tab bar
                        Color.clear
                            .frame(height: 100)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                // Rest countdown stays pinned on top while the sheet is dismissed,
                // so it survives scrolling through the exercise list.
                // The way out of a session is always on screen: quiet while
                // sets remain, lime the moment the last one is checked.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if workoutSession.isActive, !workoutSession.showSummary {
                        finishButton
                    }
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    if workoutSession.isActive, workoutSession.restTimerActive,
                       !workoutSession.restSheetVisible {
                        RestTimerBanner(session: workoutSession)
                            .padding(.horizontal, Spacing.screenH)
                            .padding(.vertical, Spacing.xs)
                            .background(BulkUpColors.background)
                    }
                }
                .refreshable {
                    if let user = authManager.user {
                        await trainingManager.loadActiveTrainingPlan(userId: user.id)
                    }
                }

                // "Comenzar Entreno" CTA — hidden during active session
                if !workoutSession.isActive,
                   viewMode == .day, let trainingDay = currentTrainingDay,
                   let dayData = trainingManager.trainingData.first(where: { $0.day == trainingDay }) {
                    if isDayCompleted(dayData) {
                        completedPill
                    } else {
                        ctaButton(inProgress: loggedExerciseCount(for: dayData) > 0)
                    }
                }
            }

            // Workout summary overlay
            if workoutSession.showSummary, let summary = workoutSession.summaryData {
                WorkoutSummaryView(
                    summary: summary,
                    saveState: workoutSession.saveState,
                    onRetry: { workoutSession.retrySave() },
                    onReview: {
                        // Same save, then straight into the recap so sensations,
                        // notes and photos can be added without hunting for it.
                        let day = workoutSession.currentDayName ?? currentTrainingDay
                        markWorkoutComplete()
                        workoutSession.saveAndDismissSummary()
                        if let day {
                            recapSelection = RecapSelection(day: day)
                        }
                    },
                    onSave: {
                        // Save and mark complete
                        markWorkoutComplete()
                        workoutSession.saveAndDismissSummary()
                    },
                    userId: authManager.user?.id,
                    dayName: workoutSession.currentDayName
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .sheet(isPresented: $showFeedback) {
            WorkoutFeedbackView(dayName: feedbackDayName, planId: trainingManager.trainingPlanId,
                                weekStart: trainingManager.weekString(for: trainingManager.selectedWeek))
        }
        .sheet(item: $recapSelection) { selection in
            if let dayData = trainingManager.trainingData.first(where: { $0.day == selection.day }) {
                WorkoutRecapSheet(dayData: dayData)
                    .environmentObject(trainingManager)
                    .environmentObject(authManager)
            } else {
                // Shouldn't happen (the day came from trainingData); visible > blank.
                Text("No se pudo cargar el resumen")
                    .foregroundColor(BulkUpColors.textSecondary)
                    .padding()
            }
        }
    }

    // MARK: - CTA Button

    private func ctaButton(inProgress: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            if workoutSession.isActive {
                // Already active — expand first incomplete
                expandFirstIncomplete()
            } else {
                // Start session
                if let trainingDay = currentTrainingDay,
                   let dayData = trainingManager.trainingData.first(where: { $0.day == trainingDay }) {
                    let dayLabel = dayData.workoutName ?? formatDayName(dayData.day)
                    workoutSession.startWorkout(dayName: trainingDay, workoutName: dayLabel, trainingManager: trainingManager)
                    Task { await HealthStore.shared.requestAuthorizationIfNeeded() }
                    expandFirstIncomplete()
                }
            }
        } label: {
            Text(inProgress ? "Continuar entreno" : "Empezar entreno")
                .primaryButtonStyle()
        }
        .pressable()
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.md)
    }

    private var completedPill: some View {
        let day = currentTrainingDay ?? selectedDay
        let savedFeedback = WorkoutFeedbackManager.shared.feedback(
            planId: trainingManager.trainingPlanId,
            dayName: day,
            weekStart: trainingManager.weekString(for: trainingManager.selectedWeek)
        )
        let savedEmoji = savedFeedback.flatMap { WorkoutFeedbackManager.emoji(for: $0.rating) }
        return HStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "checkmark")
                    .font(.system(.caption, weight: .bold))
                    .foregroundColor(Color.onFill(BulkUpColors.complete))
                    .frame(width: 26, height: 26)
                    .background(BulkUpColors.complete)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                Text("Completado")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                if let emoji = savedEmoji {
                    Text(emoji).font(.system(.body))
                }
            }

            Spacer()

            // Recap: totals, sensations and every logged set (editable)
            Button {
                recapSelection = RecapSelection(day: day)
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text("Ver resumen")
                        .font(.system(.subheadline, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(.caption2, weight: .bold))
                }
                .foregroundColor(BulkUpColors.textPrimary)
                .padding(.horizontal, Spacing.md)
                .frame(minHeight: 40)
                .background(BulkUpColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .lift(stroke: BulkUpColors.complete.opacity(0.6))
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Finish (always visible during a session)

    /// Exercises of the session's day still to do (skipped ones don't count).
    private var pendingExerciseCount: Int {
        guard let trainingDay = workoutSession.currentDayName ?? currentTrainingDay,
              let dayData = trainingManager.trainingData.first(where: { $0.day == trainingDay }) else { return 0 }
        let normalizedDay = dayData.day.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        return dayData.exercises.filter { ex in
            if workoutSession.isExerciseSkipped(day: normalizedDay, exerciseIndex: ex.orderIndex) { return false }
            let total = trainingManager.effectiveSets(for: ex, day: normalizedDay)
            return !workoutSession.isExerciseComplete(day: normalizedDay, exerciseIndex: ex.orderIndex, totalSets: total)
        }.count
    }

    private var finishButton: some View {
        let done = pendingExerciseCount == 0
        return Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if done { finishWorkoutSession() } else { showFinishConfirm = true }
        } label: {
            Text(done ? LocalizedStringKey("Todo hecho · finalizar entreno") : LocalizedStringKey("Finalizar entreno"))
                .font(.system(.headline, weight: .semibold))
                .foregroundColor(done ? BulkUpColors.onAccent : BulkUpColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
                .background(done ? BulkUpColors.accent : BulkUpColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                .lift(CornerRadius.medium)
                .contentTransition(.opacity)
        }
        .pressable()
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: done)
        .onChange(of: done) { _, now in
            if now { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.sm)
        // The list fades out under the button instead of showing through it.
        .background {
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, BulkUpColors.background], startPoint: .top, endPoint: .bottom)
                    .frame(height: 28)
                BulkUpColors.background
            }
            .padding(.top, -28)
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
        .confirmationDialog("Finalizar entreno", isPresented: $showFinishConfirm, titleVisibility: .visible) {
            Button("Finalizar igualmente") { finishWorkoutSession() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(String(format: NSLocalizedString("Quedan %lld ejercicios sin terminar", comment: ""), pendingExerciseCount))
        }
    }

    /// Open the exercise card Hoy asked for (today's day), then clear the intent.
    private func consumePendingExercise() {
        guard let pending = trainingManager.pendingExerciseToOpen else { return }
        trainingManager.pendingExerciseToOpen = nil
        currentDate = Date()
        viewMode = .day
        guard let dayData = trainingManager.trainingData.first(where: { $0.day == pending.day }),
              let exercise = dayData.exercises.first(where: { $0.orderIndex == pending.orderIndex }) else {
            expandFirstIncomplete()
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            expandedExercises.insert(exerciseRowId(exercise, day: pending.day))
        }
    }

    private func expandFirstIncomplete() {
        guard let trainingDay = currentTrainingDay,
              let dayData = trainingManager.trainingData.first(where: { $0.day == trainingDay }) else { return }
        let normalizedDay = dayData.day.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        if let firstIncomplete = dayData.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }).first(where: { ex in
            if workoutSession.isActive {
                // Skip discarded exercises
                if workoutSession.isExerciseSkipped(day: normalizedDay, exerciseIndex: ex.orderIndex) { return false }
                let total = trainingManager.effectiveSets(for: ex, day: normalizedDay)
                return !workoutSession.isExerciseComplete(day: normalizedDay, exerciseIndex: ex.orderIndex, totalSets: total)
            } else {
                let total = trainingManager.effectiveSets(for: ex, day: normalizedDay)
                return trainingManager.getCompletedSets(
                    day: normalizedDay,
                    exerciseIndex: ex.orderIndex,
                    exerciseName: ex.name,
                    totalSets: total
                ) < total
            }
        }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                let rowId = exerciseRowId(firstIncomplete, day: trainingDay)
                expandedExercises.insert(rowId)
            }
        }
    }

    /// Point the browsed date at the active session's day. The session day is
    /// today or a recent past day (8h restore cutoff), so a short backwards walk
    /// finds the matching date.
    private func syncToActiveSessionDay() {
        guard workoutSession.isActive,
              let sessionDay = workoutSession.currentDayName,
              currentTrainingDay != sessionDay else { return }
        for offset in 0...6 {
            if let d = calendar.date(byAdding: .day, value: -offset, to: Date()),
               getTrainingDayForDate(d) == sessionDay {
                currentDate = d
                return
            }
        }
    }

    private func finishWorkoutSession() {
        let _ = workoutSession.finishWorkout(trainingManager: trainingManager)

        // Persist session to backend
        if let userId = authManager.user?.id {
            workoutSession.saveSessionToBackend(
                userId: userId,
                planId: trainingManager.trainingPlanId,
                trainingManager: trainingManager
            )
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Navigation Header

    @ViewBuilder
    private var navigationHeader: some View {
        VStack(spacing: Spacing.md) {
            if viewMode == .day {
                dayNavigationContent
            } else {
                weekNavigationContent
            }
        }
    }

    private var dayNavigationContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Date navigation row
            HStack(alignment: .center) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(.footnote, weight: .bold))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(BulkUpColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                }

                Text(compactDateLabel)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .padding(.horizontal, Spacing.sm)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(.footnote, weight: .bold))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(BulkUpColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                }

                Spacer()

                if !calendar.isDateInToday(currentDate) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            currentDate = Date()
                        }
                    } label: {
                        Text("Hoy")
                            .font(.system(.footnote, weight: .semibold))
                            .foregroundColor(BulkUpColors.accentText)
                            .padding(.horizontal, Spacing.sm + 4)
                            .frame(minHeight: 32)
                            .background(BulkUpColors.accent.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                    }
                }
            }

            // 7-day mini calendar strip
            miniCalendarStrip

            // Workout name + progress
            if let trainingDay = currentTrainingDay,
               let dayData = trainingManager.trainingData.first(where: { $0.day == trainingDay }) {
                let dayLabel = dayData.workoutName ?? formatDayName(dayData.day)
                let logged = loggedExerciseCount(for: dayData)
                let total = dayData.exercises.count
                let progress: CGFloat = isDayCompleted(dayData) ? 1
                    : (total > 0 ? CGFloat(logged) / CGFloat(total) : 0)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(dayLabel)
                            .titleVoice(.largeTitle)
                            .foregroundColor(BulkUpColors.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: Spacing.md)
                        Text("\(logged)/\(total)")
                            .font(BulkUpFont.numeric(.subheadline, weight: .semibold))
                            .foregroundColor(progress >= 1.0 ? BulkUpColors.complete : BulkUpColors.textSecondary)
                    }
                    // Progress rule: lime while in progress, sky when the day is done.
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(BulkUpColors.line)
                            Rectangle()
                                .fill(progress >= 1.0 ? BulkUpColors.complete : BulkUpColors.accent)
                                .frame(width: geo.size.width * progress)
                                .animation(.easeOut(duration: 0.4), value: progress)
                        }
                    }
                    .frame(height: 3)
                }
            }
        }
    }

    // MARK: - Mini Calendar Strip

    private var miniCalendarStrip: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                let isCurrent = index == currentWeekdayIndex
                let hasWorkout = workoutDayIndices.contains(index)

                Button {
                    if let targetDate = dateForWeekIndex(index) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentDate = targetDate
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(weekDayLetters[index])
                            .font(.system(.caption2, weight: isCurrent ? .bold : .medium))
                            .foregroundColor(isCurrent ? BulkUpColors.textPrimary : BulkUpColors.textSecondary)

                        // Day number for current week
                        ZStack {
                            if isCurrent {
                                RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                    .fill(BulkUpColors.accent)
                                    .frame(width: 30, height: 30)
                            }

                            Text(dayNumberForWeekIndex(index))
                                .font(BulkUpFont.numeric(.subheadline, weight: isCurrent ? .bold : .medium))
                                .foregroundColor(isCurrent ? BulkUpColors.onAccent : BulkUpColors.textPrimary)
                        }
                        .frame(width: 30, height: 30)

                        // Workout dot
                        Circle()
                            .fill(hasWorkout && !isCurrent ? BulkUpColors.textSecondary : .clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.sm)
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .lift()
    }

    private func dateForWeekIndex(_ index: Int) -> Date? {
        let weekday = calendar.component(.weekday, from: currentDate)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: currentDate) else {
            return nil
        }
        return calendar.date(byAdding: .day, value: index, to: monday)
    }

    private func dayNumberForWeekIndex(_ index: Int) -> String {
        guard let date = dateForWeekIndex(index) else { return "" }
        return "\(calendar.component(.day, from: date))"
    }

    private var weekNavigationContent: some View {
        HStack(alignment: .center) {
            Button {
                Task {
                    await trainingManager.changeWeek(direction: .previous)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(.footnote, weight: .bold))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }

            Text(weekRangeLabel)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundColor(BulkUpColors.textPrimary)
                .padding(.horizontal, Spacing.sm)

            Button {
                Task {
                    await trainingManager.changeWeek(direction: .next)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(.footnote, weight: .bold))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }

            Spacer()
        }
        .disabled(workoutSession.isActive)
        .opacity(workoutSession.isActive ? 0.4 : 1)
    }

    // MARK: - Day View

    @ViewBuilder
    private var dayView: some View {
        if let trainingDay = currentTrainingDay,
           let selectedDayData = trainingManager.trainingData.first(where: { $0.day == trainingDay }) {
            let sortedExercises = selectedDayData.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })

            VStack(spacing: 10) {
                ForEach(sortedExercises, id: \.id) { exercise in
                    let rowId = exerciseRowId(exercise, day: trainingDay)
                    let isExpanded = expandedExercises.contains(rowId)

                    ExerciseCardView(
                        exercise: exercise,
                        exerciseIndex: exercise.orderIndex,
                        dayName: trainingDay,
                        currentDate: currentDate,
                        isExpanded: isExpanded,
                        onToggleExpand: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                if expandedExercises.contains(rowId) {
                                    expandedExercises.remove(rowId)
                                } else {
                                    expandedExercises.insert(rowId)
                                }
                            }
                        },
                        onShowProgress: {
                            progressExercise = ProgressExerciseSelection(
                                name: exercise.name,
                                orderIndex: exercise.orderIndex,
                                weightTracking: exercise.weightTracking
                            )
                        }
                    )
                    .environmentObject(trainingManager)
                    .environmentObject(authManager)
                }
            }
        } else {
            restDayView
        }
    }

    private var restDayView: some View {
        VStack(spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(currentTrainingDay == nil ? "Descanso" : "Sin ejercicios para este día")
                    .titleVoice(.largeTitle)
                    .foregroundColor(BulkUpColors.textPrimary)
                Text("Recupera energía para mañana")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.sm)
        }
    }

    // MARK: - Week View

    @ViewBuilder
    private var weekView: some View {
        VStack(spacing: 10) {
            ForEach(Array(trainingManager.trainingData.enumerated()), id: \.offset) { index, day in
                weekDayCard(for: day, at: index)
            }
        }
    }

    @ViewBuilder
    private func weekDayCard(for day: TrainingDay, at index: Int) -> some View {
        let isExpanded = expandedDay == index
        let dayLabel = day.workoutName ?? formatDayName(day.day)
        let logged = loggedExerciseCount(for: day)
        let allComplete = isDayCompleted(day)

        VStack(spacing: 0) {
            // Row header
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    expandedDay = expandedDay == index ? nil : index
                }
            }) {
                HStack(spacing: Spacing.md) {
                    // Done mark
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(allComplete ? BulkUpColors.complete : BulkUpColors.line, lineWidth: 1.5)
                            .frame(width: 28, height: 28)

                        if allComplete {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(BulkUpColors.complete)
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.system(.caption2, weight: .bold))
                                .foregroundColor(Color.onFill(BulkUpColors.complete))
                        } else if logged > 0 {
                            Text("\(logged)")
                                .font(BulkUpFont.numeric(.caption, weight: .semibold))
                                .foregroundColor(BulkUpColors.accentText)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatDayName(day.day))
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)

                        if day.workoutName != nil {
                            Text(dayLabel)
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                        }
                    }

                    Spacer()

                    Text("\(day.exercises.count) ej.")
                        .font(BulkUpFont.numeric(.caption))
                        .foregroundColor(BulkUpColors.textSecondary)

                    Image(systemName: "chevron.down")
                        .font(.system(.caption2, weight: .bold))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Completed day → recap (sensations, notes, photos, editable sets).
            // Outside the header button so the tap isn't swallowed by it.
            if allComplete {
                Button {
                    recapSelection = RecapSelection(day: day.day)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "list.clipboard.fill")
                            .font(.system(size: 13))
                        Text("Ver resumen")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .opacity(0.6)
                    }
                    .foregroundColor(BulkUpColors.complete)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm + 2)
                    .overlay(Rectangle().frame(height: 1).foregroundColor(BulkUpColors.line), alignment: .top)
                }
                .buttonStyle(.plain)
            }

            // Expanded exercises
            if isExpanded {
                VStack(spacing: 10) {
                    let sortedExercises = day.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
                    let dateForThisDay = getDateForTrainingDay(day.day)

                    ForEach(sortedExercises, id: \.id) { exercise in
                        let rowId = exerciseRowId(exercise, day: day.day)
                        let exerciseExpanded = expandedExercises.contains(rowId)

                        ExerciseCardView(
                            exercise: exercise,
                            exerciseIndex: exercise.orderIndex,
                            dayName: day.day,
                            currentDate: dateForThisDay,
                            isExpanded: exerciseExpanded,
                            onToggleExpand: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if expandedExercises.contains(rowId) {
                                        expandedExercises.remove(rowId)
                                    } else {
                                        expandedExercises.insert(rowId)
                                    }
                                }
                            }
                        )
                        .environmentObject(trainingManager)
                        .environmentObject(authManager)
                    }
                }
                .padding(.bottom, Spacing.sm)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .lift(stroke: allComplete ? BulkUpColors.complete.opacity(0.6) : nil)
        .padding(.horizontal, Spacing.screenH)
    }

    // MARK: - Helpers

    private func getDateForTrainingDay(_ dayName: String) -> Date {
        let dayMapping: [String: Int] = [
            "lunes": 1, "martes": 2, "miercoles": 3, "jueves": 4,
            "viernes": 5, "sabado": 6, "domingo": 7,
        ]

        let today = Date()
        let calendar = Calendar.current

        let normalized = dayName.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        guard let targetWeekday = dayMapping[normalized] else {
            return today
        }

        let weekStart = trainingManager.getWeekStart(trainingManager.selectedWeek)
        let daysFromMonday = (targetWeekday == 1) ? 6 : targetWeekday - 2
        let targetDate = calendar.date(byAdding: .day, value: daysFromMonday, to: weekStart) ?? today

        return targetDate
    }

    private func formatDayName(_ day: String) -> String {
        return WeekdayLabel.localized(day)
    }
}

// MARK: - Workout Completion Sheet

struct WorkoutCompletionSheet: View {
    let exerciseCount: Int
    let totalSets: Int
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    @ObservedObject private var friendsManager = FriendsManager.shared
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                    .fill(BulkUpColors.complete)
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark")
                    .font(.system(.title, weight: .bold))
                    .foregroundColor(Color.onFill(BulkUpColors.complete))
            }

            VStack(spacing: Spacing.sm) {
                Text("Entreno completado")
                    .titleVoice(.title)
                    .foregroundColor(BulkUpColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Has completado todos los ejercicios de hoy")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: Spacing.xxl) {
                VStack(spacing: Spacing.xs) {
                    Text("\(exerciseCount)")
                        .font(BulkUpFont.mono(28, weight: .semibold, relativeTo: .title))
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text("Ejercicios")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                Rectangle().fill(BulkUpColors.line).frame(width: 1, height: 40)

                VStack(spacing: Spacing.xs) {
                    Text("\(totalSets)")
                        .font(BulkUpFont.mono(28, weight: .semibold, relativeTo: .title))
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text("Series")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, Spacing.xxl)
            .background(BulkUpColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .lift()

            VStack(spacing: Spacing.md) {
                Button {
                    isLoading = true
                    onConfirm()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if isLoading {
                            ProgressView()
                                .tint(BulkUpColors.onAccent)
                        } else {
                            Image(systemName: "flame.fill")
                        }
                        Text("Registrar para mi racha")
                    }
                    .primaryButtonStyle()
                }
                .disabled(isLoading)

                Button {
                    onDismiss()
                } label: {
                    Text("Cerrar")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.xl)

            Spacer()
        }
        .padding()
        .background(BulkUpColors.background)
    }
}

// Extension helper para clamp
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

// MARK: - Progress Exercise Selection

/// Lightweight Identifiable carrier used for navigationDestination(item:)
/// so TrainingView can push ExerciseProgressView without embedding a NavigationLink
/// inside ExerciseCardView (which is reused outside NavigationStacks).
struct ProgressExerciseSelection: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let orderIndex: Int
    let weightTracking: Bool
}
