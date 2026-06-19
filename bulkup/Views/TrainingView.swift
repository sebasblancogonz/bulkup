import SwiftData
import SwiftUI

struct TrainingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var trainingManager: TrainingManager
    @ObservedObject private var friendsManager = FriendsManager.shared
    @ObservedObject private var workoutSession = WorkoutSessionManager.shared
    @State private var viewMode: ViewMode = .day
    @State private var selectedDay = ""
    @State private var expandedDay: Int? = nil
    @State private var expandedExercises: Set<String> = []
    @State private var currentDayIndex = 0

    // Date navigation
    @State private var currentDate: Date = Date()

    // Workout completion prompt
    @State private var showingCompletionPrompt = false
    @State private var completionExerciseCount = 0
    @State private var completionTotalSets = 0
    @AppStorage("lastCompletionPromptDate") private var lastCompletionPromptDate: String = ""

    enum ViewMode: String, CaseIterable {
        case week = "week"
        case day = "day"

        var displayName: String {
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
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE"
        f.calendar = Calendar(identifier: .gregorian)
        f.calendar?.firstWeekday = 2
        return f
    }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "es_ES")
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
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE d MMM"
        return f.string(from: currentDate).lowercased()
    }

    private var weekRangeLabel: String {
        let start = trainingManager.getWeekStart(trainingManager.selectedWeek)
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
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
                totalSets: ex.sets
            ) > 0
        }.count
    }

    /// Weekday index (Mon=0...Sun=6) for current date
    private var currentWeekdayIndex: Int {
        let weekday = calendar.component(.weekday, from: currentDate)
        return (weekday + 5) % 7
    }

    /// Day letters for calendar strip
    private let weekDayLetters = ["L", "M", "X", "J", "V", "S", "D"]

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
        .background(BulkUpColors.background)
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

            Task {
                await friendsManager.loadTodayStatus()
            }
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
        // Rest timer sheet
        .sheet(isPresented: $workoutSession.restTimerActive) {
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

        Task {
            await friendsManager.toggleTodayCompletion(
                userId: userId,
                planId: trainingManager.trainingPlanId,
                dayName: currentTrainingDay
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
                .refreshable {
                    if let user = authManager.user {
                        await trainingManager.loadActiveTrainingPlan(userId: user.id)
                    }
                }

                // "Comenzar Entreno" CTA — hidden during active session
                if !workoutSession.isActive,
                   viewMode == .day, let trainingDay = currentTrainingDay,
                   let dayData = trainingManager.trainingData.first(where: { $0.day == trainingDay }) {
                    let logged = loggedExerciseCount(for: dayData)
                    let allComplete = logged == dayData.exercises.count && dayData.exercises.count > 0

                    if allComplete {
                        completedPill
                    } else {
                        ctaButton(inProgress: logged > 0)
                    }
                }
            }

            // Workout summary overlay
            if workoutSession.showSummary, let summary = workoutSession.summaryData {
                WorkoutSummaryView(summary: summary) {
                    // Save and mark complete
                    markWorkoutComplete()
                    workoutSession.saveAndDismissSummary()
                }
                .transition(.opacity)
                .zIndex(100)
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
                    expandFirstIncomplete()
                }
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: inProgress ? "arrow.right.circle.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(inProgress ? "Continuar Entreno" : "Comenzar Entreno")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(BulkUpColors.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(BulkUpColors.accentGradient)
            .cornerRadius(14)
            .shadow(color: BulkUpColors.accent.opacity(0.2), radius: 12, y: 4)
        }
        .pressable()
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.md)
    }

    private var completedPill: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
            Text("Completado")
                .font(.system(size: 17, weight: .bold))
        }
        .foregroundColor(BulkUpColors.success)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(BulkUpColors.success.opacity(0.1))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(BulkUpColors.success.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.md)
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
                let total = ex.sets + workoutSession.extraSets(day: normalizedDay, exerciseIndex: ex.orderIndex)
                return !workoutSession.isExerciseComplete(day: normalizedDay, exerciseIndex: ex.orderIndex, totalSets: total)
            } else {
                return trainingManager.getCompletedSets(
                    day: normalizedDay,
                    exerciseIndex: ex.orderIndex,
                    exerciseName: ex.name,
                    totalSets: ex.sets
                ) < ex.sets
            }
        }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                let rowId = exerciseRowId(firstIncomplete, day: trainingDay)
                expandedExercises.insert(rowId)
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
            // Inline segmented view mode toggle
            HStack(spacing: 0) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            viewMode = mode
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 11, weight: .medium))
                            Text(mode.displayName)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(viewMode == mode ? BulkUpColors.onAccent : BulkUpColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            viewMode == mode
                                ? BulkUpColors.accent
                                : Color.clear
                        )
                        .cornerRadius(8)
                    }
                }
            }
            .padding(3)
            .background(BulkUpColors.surfaceElevated)
            .cornerRadius(10)

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
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(BulkUpColors.surfaceElevated)
                        .clipShape(Circle())
                }

                Text(compactDateLabel)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .padding(.horizontal, Spacing.sm)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(BulkUpColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(BulkUpColors.surfaceElevated)
                        .clipShape(Circle())
                }

                Spacer()

                if !calendar.isDateInToday(currentDate) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            currentDate = Date()
                        }
                    } label: {
                        Text("Hoy")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BulkUpColors.accent)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(BulkUpColors.accent.opacity(0.1))
                            .clipShape(Capsule())
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
                let progress: CGFloat = total > 0 ? CGFloat(logged) / CGFloat(total) : 0

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(dayLabel)
                            .font(BulkUpFont.largeTitle())
                            .foregroundColor(BulkUpColors.textPrimary)
                    }

                    Spacer()

                    // Progress ring (48pt)
                    ZStack {
                        GradientProgressRing(
                            progress: progress,
                            lineWidth: 6,
                            size: 48,
                            color: progress >= 1.0 ? BulkUpColors.success : BulkUpColors.accent
                        )
                        Text("\(logged)/\(total)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
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
                            .font(.system(size: 11, weight: isCurrent ? .bold : .medium))
                            .foregroundColor(isCurrent ? BulkUpColors.textPrimary : BulkUpColors.textTertiary)

                        // Day number for current week
                        ZStack {
                            if isCurrent {
                                Circle()
                                    .fill(BulkUpColors.accent)
                                    .frame(width: 28, height: 28)
                            }

                            Text(dayNumberForWeekIndex(index))
                                .font(.system(size: 12, weight: isCurrent ? .bold : .regular))
                                .foregroundColor(isCurrent ? BulkUpColors.onAccent : BulkUpColors.textSecondary)
                        }
                        .frame(width: 28, height: 28)

                        // Workout dot
                        Circle()
                            .fill(hasWorkout && !isCurrent ? BulkUpColors.accent : .clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Spacing.sm)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(Circle())
            }

            Text(weekRangeLabel)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(BulkUpColors.textPrimary)
                .padding(.horizontal, Spacing.sm)

            Button {
                Task {
                    await trainingManager.changeWeek(direction: .next)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(Circle())
            }

            Spacer()
        }
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
            HStack(spacing: Spacing.md) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 24))
                    .foregroundColor(BulkUpColors.accentMuted)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currentTrainingDay == nil ? "Descanso" : "Sin ejercicios para este dia")
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text("Recupera energia para manana")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                Spacer()
            }
            .padding(Spacing.md)
            .background(BulkUpColors.surface)
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
            )
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.lg)
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
        let allComplete = logged == day.exercises.count && day.exercises.count > 0

        VStack(spacing: 0) {
            // Row header
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    expandedDay = expandedDay == index ? nil : index
                }
            }) {
                HStack(spacing: Spacing.md) {
                    // Completion indicator
                    ZStack {
                        Circle()
                            .stroke(
                                allComplete ? BulkUpColors.accent : Color(hex: "#2A2A2A"),
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)

                        if allComplete {
                            Circle()
                                .fill(BulkUpColors.accent.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(BulkUpColors.accent)
                        } else if logged > 0 {
                            Text("\(logged)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(BulkUpColors.accent)
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
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)
                        .fontDesign(.monospaced)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
                .padding(Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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
        .cornerRadius(CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
        // Completed: accent left border
        .overlay(alignment: .leading) {
            if allComplete {
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
        return day.capitalized
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "dia", with: "Día")
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
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [BulkUpColors.success.opacity(0.2), BulkUpColors.success.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(BulkUpColors.success)
            }
            .shadow(color: BulkUpColors.success.opacity(0.2), radius: 20, x: 0, y: 10)

            VStack(spacing: Spacing.sm) {
                Text("Entrenamiento Completado!")
                    .font(BulkUpFont.largeTitle())
                    .foregroundColor(BulkUpColors.textPrimary)

                Text("Has completado todos los ejercicios de hoy")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: Spacing.xxl) {
                VStack(spacing: Spacing.xs) {
                    Text("\(exerciseCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(BulkUpColors.accent)
                    Text("Ejercicios")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: Spacing.xs) {
                    Text("\(totalSets)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(BulkUpColors.accent)
                    Text("Series")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
            .padding(.vertical, Spacing.lg)
            .padding(.horizontal, Spacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(BulkUpColors.surfaceElevated)
            )

            VStack(spacing: Spacing.md) {
                Button {
                    isLoading = true
                    onConfirm()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "flame.fill")
                        }
                        Text("Registrar para mi racha")
                            .fontWeight(.semibold)
                    }
                    .primaryButtonStyle(color: BulkUpColors.accent)
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
