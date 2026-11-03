//
//  TodayView.swift
//  bulkup
//
//  Today: the day's workout set like a plate on the bar, one strip of evidence,
//  the exercises and meals as hairline lists. Graphite & Voltage grammar.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var trainingManager = TrainingManager.shared
    @ObservedObject private var dietManager = DietManager.shared
    @ObservedObject private var mealTrackingManager = MealTrackingManager.shared
    @ObservedObject private var friendsManager = FriendsManager.shared
    @ObservedObject private var measurementsManager = BodyMeasurementsManager.shared

    @ObservedObject private var workoutSession = WorkoutSessionManager.shared

    @State private var hasAppeared = false
    @State private var animateStats = false

    // MARK: - Date Helpers

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = LanguageManager.shared.locale
        cal.firstWeekday = 2
        return cal
    }

    /// "lunes 14 nov" — same shape as the Entreno date nav
    private var compactDate: String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.locale
        f.dateFormat = "EEEE d MMM"
        return f.string(from: Date()).lowercased()
    }

    /// Normalized day name for matching: lowercase, no diacritics
    private var todayDayName: String {
        let f = DateFormatter()
        // Matched against the plan's Spanish day-name data — must stay Spanish,
        // NOT the app/display locale (English would yield "monday" ≠ "lunes").
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE"
        return f.string(from: Date()).lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
    }

    /// Weekday index: Monday=0 ... Sunday=6
    private var todayWeekdayIndex: Int {
        let weekday = calendar.component(.weekday, from: Date())
        return (weekday + 5) % 7
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private var streakCount: Int {
        friendsManager.myStreak?.currentStreak ?? 0
    }

    // MARK: - Day Matching (robust)

    private func normalizeDayName(_ raw: String) -> String {
        raw.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }

    private static let spanishDayOrder: [String: Int] = [
        "lunes": 0, "martes": 1, "miercoles": 2, "jueves": 3,
        "viernes": 4, "sabado": 5, "domingo": 6,
    ]

    private func weekdayIndex(for dayString: String) -> Int? {
        let norm = normalizeDayName(dayString)
        if let idx = Self.spanishDayOrder[norm] {
            return idx
        }
        let stripped = norm.replacingOccurrences(of: "dia", with: "")
            .trimmingCharacters(in: .whitespaces)
        if let num = Int(stripped) {
            return (num - 1) % 7
        }
        return nil
    }

    private var todayTrainingDay: TrainingDay? {
        let data = trainingManager.trainingData
        guard !data.isEmpty else { return nil }
        if data.count == 1 { return data.first }
        if let match = data.first(where: { normalizeDayName($0.day) == todayDayName }) {
            return match
        }
        if let match = data.first(where: { weekdayIndex(for: $0.day) == todayWeekdayIndex }) {
            return match
        }
        return nil
    }

    private var todayDietDay: DietDay? {
        let data = dietManager.dietData
        guard !data.isEmpty else { return nil }
        if data.count == 1 { return data.first }
        if let match = data.first(where: { normalizeDayName($0.day) == todayDayName }) {
            return match
        }
        if let match = data.first(where: { weekdayIndex(for: $0.day) == todayWeekdayIndex }) {
            return match
        }
        return nil
    }

    private var latestWeight: Double? {
        measurementsManager.currentMeasurements?.peso
    }

    private var weeklyComplianceRate: Double? {
        guard let stats = mealTrackingManager.complianceStats else { return nil }
        return stats.complianceRate
    }

    private var weeklyTrainingSummary: (completed: Int, total: Int) {
        let total = trainingManager.trainingData.count
        var completed = 0

        for day in trainingManager.trainingData {
            let norm = normalizeDayName(day.day)
            guard let dayIdx = Self.spanishDayOrder[norm], dayIdx <= todayWeekdayIndex else { continue }
            let status = trainingManager.getDayCompletionStatus(dayName: day.day)
            if status.allComplete { completed += 1 }
        }

        return (completed, total)
    }

    /// Localized single-letter weekday symbols, Monday-first (e.g. ES: L M M J V S D, EN: M T W T F S S)
    private var weekDayLetters: [String] {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.locale
        // veryShortWeekdaySymbols is Sunday-first; reorder to Monday-first.
        let symbols = f.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        return Array(symbols[1...]) + [symbols[0]]
    }

    /// Calendar date for a Monday-first week index (0=Mon ... 6=Sun) in the current week
    private func dateForWeekIndex(_ index: Int) -> Date? {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return nil }
        return calendar.date(byAdding: .day, value: index, to: weekStart)
    }

    /// Day-of-month string for the strip (e.g. "14"); empty if uncomputable
    private func dayNumber(for index: Int) -> String {
        guard let date = dateForWeekIndex(index) else { return "" }
        return "\(calendar.component(.day, from: date))"
    }

    /// Completed day indices this week (Mon=0...Sun=6)
    private var completedDayIndices: Set<Int> {
        var indices = Set<Int>()
        for day in trainingManager.trainingData {
            let norm = normalizeDayName(day.day)
            guard let dayIdx = Self.spanishDayOrder[norm] else { continue }
            let status = trainingManager.getDayCompletionStatus(dayName: day.day)
            if status.allComplete { indices.insert(dayIdx) }
        }
        return indices
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Greeting + streak
                    greetingHeader
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.top, Spacing.sm)
                        .padding(.bottom, Spacing.md)

                    // Week strip
                    calendarStrip
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.bottom, Spacing.md)

                    // Today's workout: the headline of the day
                    heroWorkoutCard
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.bottom, Spacing.lg)

                    // One strip of evidence
                    quickStatsRow
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.bottom, Spacing.sectionGap)

                    // Training section (exercise list)
                    trainingSection
                        .padding(.bottom, Spacing.lg)

                    // Meals section
                    mealsSection
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.bottom, Spacing.lg)

                    // Bottom spacer for floating tab bar
                    Color.clear.frame(height: 100)
                }
            }
            .scrollIndicators(.hidden)
            .background(BulkUpGround())
            .refreshable {
                await loadAllData()
            }
            .task {
                guard !hasAppeared else { return }
                hasAppeared = true
                await loadAllData()
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    animateStats = true
                }
            }
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            greetingTextView
                .font(.system(.subheadline, weight: .medium))
                .foregroundColor(BulkUpColors.textSecondary)
                .lineLimit(1)

            Spacer(minLength: Spacing.sm)

            if streakCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(.caption2, weight: .bold))
                    Text("\(streakCount)")
                        .font(BulkUpFont.numeric(.footnote, weight: .semibold))
                    Text("días")
                        .font(.system(.footnote, weight: .medium))
                }
                .foregroundColor(BulkUpColors.accentText)
                .accessibilityLabel(Text("\(streakCount)-day streak"))
            }

            if friendsManager.todayCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(.footnote))
                    .foregroundColor(BulkUpColors.complete)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Entreno de hoy completado")
            }

            Text(compactDate)
                .font(BulkUpFont.numeric(.footnote, weight: .medium))
                .foregroundColor(BulkUpColors.textTertiary)
        }
    }

    private var greetingKey: LocalizedStringKey {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Buenos días" }
        else if hour < 20 { return "Buenas tardes" }
        else { return "Buenas noches" }
    }

    /// Returns a live-switching localized greeting `Text`, with optional name suffix.
    private var greetingTextView: some View {
        let name = authManager.user?.name.components(separatedBy: " ").first ?? ""
        return Group {
            if name.isEmpty {
                Text(greetingKey)
            } else {
                Text("\(Text(greetingKey)), \(name)")
            }
        }
    }

    // MARK: - Calendar Strip

    private var calendarStrip: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                CalendarDayView(
                    dayLetter: weekDayLetters[index],
                    dayNumber: dayNumber(for: index),
                    isToday: index == todayWeekdayIndex,
                    isCompleted: completedDayIndices.contains(index)
                )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, Spacing.sm)
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .lift()
    }

    // MARK: - Today's workout

    @ViewBuilder
    private var heroWorkoutCard: some View {
        if let day = todayTrainingDay {
            let dayLabel = day.workoutName ?? WeekdayLabel.localized(day.day)
            let totalExercises = day.exercises.count
            let loggedExercises = day.exercises.filter { ex in
                trainingManager.getCompletedSets(
                    day: normalizeDayName(day.day),
                    exerciseIndex: ex.orderIndex,
                    exerciseName: ex.name,
                    totalSets: trainingManager.effectiveSets(for: ex, day: normalizeDayName(day.day))
                ) > 0
            }.count
            let progress = totalExercises > 0 ? CGFloat(loggedExercises) / CGFloat(totalExercises) : 0
            let normalizedDay = normalizeDayName(day.day)
            let totalSets = day.exercises.reduce(0) { $0 + trainingManager.effectiveSets(for: $1, day: normalizedDay) }
            let isDone = friendsManager.todayCompleted || trainingManager.isDayCompleted(day: day.day)

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(dayLabel)
                    .titleVoice(.largeTitle)
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                if isDone {
                    Text("Completado · \(totalExercises) ejercicios · \(totalSets) series")
                        .font(BulkUpFont.numeric(.subheadline, weight: .semibold))
                        .foregroundColor(BulkUpColors.complete)
                } else {
                    Text("\(totalExercises) ejercicios · \(totalSets) series")
                        .font(BulkUpFont.numeric(.subheadline, weight: .medium))
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                // Progress rule: lime is the progress, sky is "done".
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(BulkUpColors.line)
                            Rectangle()
                                .fill(isDone ? BulkUpColors.complete : BulkUpColors.accent)
                                .frame(width: geo.size.width * (isDone ? 1 : (animateStats ? progress : 0)))
                                .animation(.easeOut(duration: 0.6), value: animateStats)
                        }
                    }
                    .frame(height: 3)

                    HStack {
                        Text("\(loggedExercises)/\(totalExercises) ejercicios registrados")
                            .font(BulkUpFont.numeric(.footnote))
                            .foregroundColor(BulkUpColors.textSecondary)
                        Spacer()
                    }
                }

                if !isDone {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        startOrResumeSession(day: day, dayLabel: dayLabel)
                    } label: {
                        Text(workoutSession.isActive || loggedExercises > 0 ? "Continuar entreno" : "Empezar entreno")
                            .primaryButtonStyle()
                    }
                    .pressable()
                }
            }
            .padding(.bottom, Spacing.sm)
        } else if !trainingManager.trainingData.isEmpty {
            // Rest day hero
            restDayHero
        }
    }

    private var restDayHero: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Descanso")
                .titleVoice(.largeTitle)
                .foregroundColor(BulkUpColors.textPrimary)
            Text("Recupera energía para mañana")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.sm)
    }

    // MARK: - Quick Stats Row

    /// One line of evidence under the day's block: this week's workouts, diet
    /// adherence, last weight. Tabular SF; no tiles, no strip.
    private var statItems: [(value: String, label: LocalizedStringKey)] {
        var items: [(value: String, label: LocalizedStringKey)] = []
        let week = weeklyTrainingSummary
        if week.total > 0 { items.append(("\(week.completed)/\(week.total)", "entrenos")) }
        if let rate = weeklyComplianceRate { items.append(("\(Int(rate * 100))%", "dieta")) }
        if let w = latestWeight { items.append((String(format: "%.1f kg", w), "peso")) }
        return items
    }

    @ViewBuilder
    private var quickStatsRow: some View {
        let items = statItems
        if !items.isEmpty {
            HStack(spacing: Spacing.xs) {
                Text("Esta semana")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)
                ForEach(items.indices, id: \.self) { i in
                    Text("·")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)
                    Text(items[i].value)
                        .font(BulkUpFont.numeric(.footnote, weight: .semibold))
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text(items[i].label)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .opacity(animateStats ? 1 : 0)
        }
    }

    // MARK: - Training Section

    @ViewBuilder
    private var trainingSection: some View {
        if trainingManager.isLoading && trainingManager.trainingData.isEmpty {
            ProgressView()
                .tint(BulkUpColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
        } else if trainingManager.trainingData.isEmpty {
            emptyStateLine(
                text: "Sin plan de entreno",
                icon: "dumbbell",
                action: {
                    NotificationCenter.default.post(name: .navigateToTraining, object: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(name: .navigateToTrainingLibrary, object: nil)
                    }
                }
            )
            .padding(.horizontal, Spacing.screenH)
        } else if let day = todayTrainingDay {
            trainingDayContent(day)
        }
    }

    private func trainingDayContent(_ day: TrainingDay) -> some View {
        let normalizedDay = normalizeDayName(day.day)
        let totalExercises = day.exercises.count
        let loggedExercises = day.exercises.filter { ex in
            trainingManager.getCompletedSets(
                day: normalizedDay,
                exerciseIndex: ex.orderIndex,
                exerciseName: ex.name,
                totalSets: trainingManager.effectiveSets(for: ex, day: normalizedDay)
            ) > 0
        }.count
        let allLogged = loggedExercises == totalExercises && totalExercises > 0

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            HStack {
                Text("Ejercicios")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                Spacer()
                Text("\(loggedExercises)/\(totalExercises)")
                    .font(BulkUpFont.numeric(.subheadline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.bottom, Spacing.xs)

            // Exercise list
            VStack(spacing: 0) {
                let sorted = day.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })
                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, exercise in
                    InlineExerciseRow(
                        exercise: exercise,
                        dayName: day.day,
                        showsSeparator: index < sorted.count - 1
                    )
                    .environmentObject(trainingManager)
                    .environmentObject(authManager)
                }
            }
            .background(BulkUpColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .lift()
            .padding(.horizontal, Spacing.screenH)

            // Complete workout action
            if allLogged && !friendsManager.todayCompleted {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    Task {
                        guard let user = authManager.user else { return }
                        await friendsManager.toggleTodayCompletion(
                            userId: user.id,
                            planId: trainingManager.trainingPlanId,
                            dayName: day.day
                        )
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                        Text("Marcar como completado")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .primaryButtonStyle()
                }
                .pressable()
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.sm)
            }
        }
    }

    /// The day's action starts the session right here; Entreno opens on the
    /// first exercise still to do.
    private func startOrResumeSession(day: TrainingDay, dayLabel: String) {
        if !workoutSession.isActive {
            workoutSession.startWorkout(dayName: day.day, workoutName: dayLabel, trainingManager: trainingManager)
        }
        openInTraining(day: day.day, orderIndex: firstIncompleteOrderIndex(day))
    }

    private func firstIncompleteOrderIndex(_ day: TrainingDay) -> Int? {
        let normalizedDay = normalizeDayName(day.day)
        return day.exercises.sorted { $0.orderIndex < $1.orderIndex }.first { ex in
            let total = trainingManager.effectiveSets(for: ex, day: normalizedDay)
            return trainingManager.getCompletedSets(
                day: normalizedDay, exerciseIndex: ex.orderIndex, exerciseName: ex.name, totalSets: total
            ) < total
        }?.orderIndex
    }

    // MARK: - Meals Section

    @ViewBuilder
    private var mealsSection: some View {
        if dietManager.isLoading && dietManager.dietData.isEmpty {
            ProgressView()
                .tint(BulkUpColors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        } else if dietManager.dietData.isEmpty {
            emptyStateLine(
                text: "Sin plan de dieta",
                icon: "fork.knife",
                action: {
                    NotificationCenter.default.post(name: .navigateToDiet, object: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(name: .navigateToDietLibrary, object: nil)
                    }
                }
            )
        } else if let dayData = todayDietDay {
            mealsContent(dayData)
        } else {
            emptyStateLine(
                text: "Sin comidas para hoy",
                icon: "fork.knife",
                action: {
                    NotificationCenter.default.post(name: .navigateToDiet, object: nil)
                }
            )
        }
    }

    private func mealsContent(_ dayData: DietDay) -> some View {
        let meals = dayData.meals.sorted { $0.orderIndex < $1.orderIndex }
        let totalMeals = meals.count
        let completedCount = mealTrackingManager.todayTracking.filter { $0.completed }.count

        return VStack(alignment: .leading, spacing: Spacing.md) {
            // Section header
            HStack {
                Text("Comidas")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                Spacer()
                if totalMeals > 0 {
                    Text("\(completedCount)/\(totalMeals)")
                        .font(BulkUpFont.numeric(.subheadline, weight: .semibold))
                        .foregroundColor(
                            completedCount == totalMeals
                                ? BulkUpColors.complete
                                : BulkUpColors.textSecondary
                        )
                        .contentTransition(.numericText())
                }
            }

            // Meal rows in a card
            VStack(spacing: 0) {
                ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                    let record = mealTrackingManager.trackingRecord(for: meal.order, date: todayDateString)
                    let isCompleted = record?.completed ?? false

                    InlineMealRow(
                        mealType: meal.type,
                        time: meal.time,
                        isCompleted: isCompleted,
                        onToggle: {
                            guard let record = record, let user = authManager.user else { return }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            Task {
                                await mealTrackingManager.toggleMealCompletion(
                                    record: record,
                                    userId: user.id
                                )
                            }
                        }
                    )

                    if index < meals.count - 1 {
                        Rectangle().fill(BulkUpColors.line).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            .background(BulkUpColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .lift()
        }
    }

    // MARK: - Shared Components

    private func emptyStateLine(text: String, icon: String = "plus", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(BulkUpColors.textTertiary)
                    .frame(width: 48, height: 48)
                    .background(BulkUpColors.surfaceElevated)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(text))
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)
                    Text("Toca para empezar")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(BulkUpColors.textTertiary)
            }
            .padding(Spacing.md)
            .background(BulkUpColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
            .lift()
        }
        .pressable()
    }

    // MARK: - Data Loading

    private func loadAllData() async {
        guard let user = authManager.user else { return }

        async let trainTask: () = trainingManager.loadTrainingDataForTab(userId: user.id)
        async let dietTask: () = dietManager.loadActiveDietPlan(userId: user.id)
        async let streakTask: () = friendsManager.loadMyStreak()
        async let todayTask: () = friendsManager.loadTodayStatus()
        async let measTask: () = measurementsManager.loadLatestMeasurements(userId: user.id)
        async let compTask: () = mealTrackingManager.loadComplianceStats(userId: user.id)

        _ = await (trainTask, dietTask, streakTask, todayTask, measTask, compTask)

        // Load today's meal tracking after diet plan is available
        if let dayData = todayDietDay {
            let meals = dayData.meals.sorted { $0.orderIndex < $1.orderIndex }
            await mealTrackingManager.loadTracking(
                userId: user.id,
                date: todayDateString,
                dayName: dayData.day,
                planId: dietManager.dietPlanId,
                meals: meals
            )
        }
    }
}

// MARK: - Inline Exercise Row

private struct InlineExerciseRow: View {
    let exercise: Exercise
    let dayName: String
    var showsSeparator: Bool = true

    @EnvironmentObject var trainingManager: TrainingManager

    private var normalizedDay: String {
        dayName.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }

    private var totalSets: Int {
        trainingManager.effectiveSets(for: exercise, day: normalizedDay)
    }

    private var completedSets: Int {
        trainingManager.getCompletedSets(
            day: normalizedDay,
            exerciseIndex: exercise.orderIndex,
            exerciseName: exercise.name,
            totalSets: totalSets
        )
    }

    private var allSetsLogged: Bool {
        completedSets == totalSets && totalSets > 0
    }

    var body: some View {
        // One instrument for kilos: the row opens its card on the Entreno tab.
        Button {
            openInTraining(day: dayName, orderIndex: exercise.orderIndex)
        } label: {
            HStack(spacing: Spacing.md) {
                // Logged mark: sky square when every set has a weight
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(
                            allSetsLogged ? BulkUpColors.complete : BulkUpColors.textTertiary.opacity(0.6),
                            lineWidth: 1.5
                        )
                        .frame(width: 26, height: 26)

                    if allSetsLogged {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(BulkUpColors.complete)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(.caption2, weight: .bold))
                            .foregroundColor(Color.onFill(BulkUpColors.complete))
                    } else if completedSets > 0 {
                        Text("\(completedSets)")
                            .font(BulkUpFont.numeric(.caption2, weight: .bold))
                            .foregroundColor(BulkUpColors.accentText)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(BulkUpFont.body())
                        .foregroundColor(allSetsLogged ? BulkUpColors.textSecondary : BulkUpColors.textPrimary)
                        .lineLimit(1)

                    Text("\(totalSets) × \(exercise.reps)")
                        .font(BulkUpFont.numeric(.footnote))
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundColor(BulkUpColors.textTertiary)
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle().fill(BulkUpColors.line).frame(height: 1).padding(.leading, Spacing.md)
            }
        }
    }
}

/// Switch to Entreno and open one exercise card there (Entreno consumes the
/// intent when it appears, so it works on a cold tab too).
@MainActor
private func openInTraining(day: String, orderIndex: Int?) {
    if let orderIndex {
        TrainingManager.shared.pendingExerciseToOpen = (day: day, orderIndex: orderIndex)
    }
    NotificationCenter.default.post(name: .navigateToTraining, object: nil)
}

// MARK: - Inline Meal Row

private struct InlineMealRow: View {
    let mealType: String
    let time: String
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isCompleted ? BulkUpColors.complete : BulkUpColors.line, lineWidth: 1.5)
                        .frame(width: 26, height: 26)

                    if isCompleted {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(BulkUpColors.complete)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(.caption2, weight: .bold))
                            .foregroundColor(Color.onFill(BulkUpColors.complete))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)

                Text(MealTypeLabel.localized(mealType))
                    .font(BulkUpFont.body())
                    .foregroundColor(isCompleted ? BulkUpColors.textSecondary : BulkUpColors.textPrimary)
                    .strikethrough(isCompleted, color: BulkUpColors.textSecondary)

                Spacer()

                if !time.isEmpty {
                    Text(time)
                        .font(BulkUpFont.numeric(.footnote, weight: .medium))
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayView()
        .environmentObject(AuthManager.shared)
}
