//
//  TodayView.swift
//  bulkup
//
//  Premium dashboard — immersive, photography-forward, Freeletics-inspired.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var trainingManager = TrainingManager.shared
    @ObservedObject private var dietManager = DietManager.shared
    @ObservedObject private var mealTrackingManager = MealTrackingManager.shared
    @ObservedObject private var friendsManager = FriendsManager.shared
    @ObservedObject private var measurementsManager = BodyMeasurementsManager.shared

    @State private var hasAppeared = false
    @State private var expandedExercises: Set<String> = []
    @State private var animateStats = false

    // MARK: - Date Helpers

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = LanguageManager.shared.locale
        cal.firstWeekday = 2
        return cal
    }

    /// "lunes 14" — lowercase day name + day number
    private var compactDate: String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.locale
        f.dateFormat = "EEEE d"
        return f.string(from: Date()).lowercased()
    }

    /// Normalized day name for matching: lowercase, no diacritics
    private var todayDayName: String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.locale
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

    /// Week day letters for calendar strip
    private let weekDayLetters = ["L", "M", "X", "J", "V", "S", "D"]

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
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.lg)

                    // Calendar strip
                    calendarStrip
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.bottom, Spacing.lg)

                    // Hero workout card
                    heroWorkoutCard
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.bottom, Spacing.lg)

                    // Quick stats row
                    quickStatsRow
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.bottom, Spacing.lg)

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
            .background(BulkUpColors.background.ignoresSafeArea())
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
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                greetingTextView
                    .font(BulkUpFont.screenTitle())
                    .foregroundColor(BulkUpColors.textPrimary)

                Spacer()

                if friendsManager.todayCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(BulkUpColors.success)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            if streakCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(BulkUpColors.warning)
                    Text("\(streakCount)-day streak")
                        .font(BulkUpFont.badge())
                        .tracking(0.5)
                        .foregroundColor(BulkUpColors.warning)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(BulkUpColors.warning.opacity(0.12))
                .clipShape(Capsule())
            }
        }
    }

    private var greetingKey: LocalizedStringKey {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Buenos dias" }
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
                    isToday: index == todayWeekdayIndex,
                    isCompleted: completedDayIndices.contains(index)
                )
            }
        }
        .padding(.vertical, 12)
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
    }

    // MARK: - Hero Workout Card

    @ViewBuilder
    private var heroWorkoutCard: some View {
        if let day = todayTrainingDay {
            let dayLabel = day.workoutName ?? day.day.capitalized
            let totalExercises = day.exercises.count
            let loggedExercises = day.exercises.filter { ex in
                trainingManager.getCompletedSets(
                    day: normalizeDayName(day.day),
                    exerciseIndex: ex.orderIndex,
                    exerciseName: ex.name,
                    totalSets: ex.sets
                ) > 0
            }.count
            let progress = totalExercises > 0 ? CGFloat(loggedExercises) / CGFloat(totalExercises) : 0

            ZStack(alignment: .bottomLeading) {
                // Gradient background with accent glow
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(
                        LinearGradient(
                            colors: [BulkUpColors.accent.opacity(0.15), BulkUpColors.surface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topTrailing) {
                        // Subtle radial glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [BulkUpColors.accent.opacity(0.08), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 120
                                )
                            )
                            .frame(width: 240, height: 240)
                            .offset(x: 40, y: -40)
                    }
                    .frame(height: 180)

                // Content overlay
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        PillBadge(text: "Hoy", color: BulkUpColors.accent, icon: "bolt.fill")

                        Text(dayLabel)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(BulkUpColors.textPrimary)

                        Text("\(totalExercises) ejercicios")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }

                    Spacer()

                    // Progress ring
                    ZStack {
                        GradientProgressRing(
                            progress: animateStats ? progress : 0,
                            lineWidth: 6,
                            size: 64,
                            color: BulkUpColors.accent
                        )
                        VStack(spacing: 0) {
                            Text("\(Int(progress * 100))")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(BulkUpColors.textPrimary)
                            Text("%")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(BulkUpColors.textSecondary)
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
            )
        } else if !trainingManager.trainingData.isEmpty {
            // Rest day hero
            restDayHero
        }
    }

    private var restDayHero: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 28))
                .foregroundColor(BulkUpColors.accentMuted)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Dia de descanso")
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
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: Spacing.md) {
            let week = weeklyTrainingSummary
            if week.total > 0 {
                StatCard(
                    value: "\(week.completed)/\(week.total)",
                    label: "Entrenos",
                    icon: "dumbbell.fill"
                )
            }

            if let rate = weeklyComplianceRate {
                StatCard(
                    value: "\(Int(rate * 100))%",
                    label: "Dieta",
                    icon: "fork.knife"
                )
            }

            if let w = latestWeight {
                StatCard(
                    value: String(format: "%.1f", w),
                    label: "Peso (kg)",
                    icon: "scalemass.fill"
                )
            }
        }
        .opacity(animateStats ? 1 : 0)
        .offset(y: animateStats ? 0 : 10)
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
                totalSets: ex.sets
            ) > 0
        }.count
        let allLogged = loggedExercises == totalExercises && totalExercises > 0

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            HStack {
                Text("EJERCICIOS")
                    .font(BulkUpFont.badge())
                    .tracking(1.5)
                    .foregroundColor(BulkUpColors.accent)
                Spacer()
                Text("\(loggedExercises)/\(totalExercises)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(BulkUpColors.textSecondary)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.bottom, Spacing.xs)

            // Exercise list
            VStack(spacing: 2) {
                ForEach(day.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { exercise in
                    InlineExerciseRow(
                        exercise: exercise,
                        dayName: day.day,
                        isExpanded: expandedExercises.contains(exerciseRowId(exercise, day: day.day)),
                        onToggleExpand: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                let id = exerciseRowId(exercise, day: day.day)
                                if expandedExercises.contains(id) {
                                    expandedExercises.remove(id)
                                } else {
                                    expandedExercises.insert(id)
                                }
                            }
                        }
                    )
                    .environmentObject(trainingManager)
                    .environmentObject(authManager)
                }
            }

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

    private func exerciseRowId(_ exercise: Exercise, day: String) -> String {
        "\(day)-\(exercise.orderIndex)-\(exercise.name)"
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
                Text("COMIDAS")
                    .font(BulkUpFont.badge())
                    .tracking(1.5)
                    .foregroundColor(BulkUpColors.diet)
                Spacer()
                if totalMeals > 0 {
                    Text("\(completedCount)/\(totalMeals)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(
                            completedCount == totalMeals
                                ? BulkUpColors.accent
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
                        Divider()
                            .background(BulkUpColors.border)
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
            .background(BulkUpColors.surface)
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
            )
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
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
            )
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
    let isExpanded: Bool
    let onToggleExpand: () -> Void

    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager

    private var normalizedDay: String {
        dayName.lowercased().folding(options: .diacriticInsensitive, locale: .current)
    }

    private var completedSets: Int {
        trainingManager.getCompletedSets(
            day: normalizedDay,
            exerciseIndex: exercise.orderIndex,
            exerciseName: exercise.name,
            totalSets: exercise.sets
        )
    }

    private var allSetsLogged: Bool {
        completedSets == exercise.sets && exercise.sets > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed row
            Button(action: onToggleExpand) {
                HStack(spacing: Spacing.md) {
                    // Completion indicator
                    ZStack {
                        Circle()
                            .stroke(
                                allSetsLogged ? BulkUpColors.accent : BulkUpColors.textTertiary.opacity(0.3),
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)

                        if allSetsLogged {
                            Circle()
                                .fill(BulkUpColors.accent.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(BulkUpColors.accent)
                        } else if completedSets > 0 {
                            Text("\(completedSets)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(BulkUpColors.training)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(BulkUpFont.body())
                            .foregroundColor(
                                allSetsLogged
                                    ? BulkUpColors.textTertiary
                                    : BulkUpColors.textPrimary
                            )
                            .lineLimit(1)

                        Text("\(exercise.sets) Sets \u{00B7} \(exercise.reps) Reps")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textTertiary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BulkUpColors.textTertiary)
                        .frame(width: 24, height: 24)
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded weight logger
            if isExpanded {
                InlineWeightLogger(
                    exercise: exercise,
                    dayName: dayName
                )
                .environmentObject(trainingManager)
                .environmentObject(authManager)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(
            isExpanded
                ? RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(BulkUpColors.surface)
                : nil
        )
        .overlay(
            isExpanded
                ? RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
                : nil
        )
        .padding(.horizontal, isExpanded ? Spacing.sm : 0)
    }
}

// MARK: - Inline Weight Logger

private struct InlineWeightLogger: View {
    let exercise: Exercise
    let dayName: String

    @EnvironmentObject var trainingManager: TrainingManager
    @EnvironmentObject var authManager: AuthManager

    @State private var weightTexts: [String] = []
    @State private var previousWeights: [Double?] = []
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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Notes
            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .padding(.horizontal, Spacing.sm)
            }

            if exercise.weightTracking {
                // Weight fields
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(0..<exercise.sets, id: \.self) { setIndex in
                            VStack(spacing: 4) {
                                Text("S\(setIndex + 1)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(BulkUpColors.textTertiary)

                                if let prev = safeGetPrevWeight(setIndex), prev > 0 {
                                    Text(formatWeight(prev))
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(BulkUpColors.textTertiary)
                                }

                                TextField("—", text: weightBinding(for: setIndex))
                                    .keyboardType(.decimalPad)
                                    .focused($focusedSet, equals: setIndex)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                                    .foregroundColor(BulkUpColors.textPrimary)
                                    .frame(width: 56, height: 40)
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
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.sm)
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
                .padding(.horizontal, Spacing.sm)
            } else {
                Text("Sin seguimiento de peso")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)
                    .padding(.horizontal, Spacing.sm)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
        .onAppear { loadInitialData() }
        .onChange(of: trainingManager.isFullyLoaded) { _, loaded in
            if loaded { loadInitialData() }
        }
    }

    // MARK: - Weight Data

    private func loadInitialData() {
        guard weightTexts.count != exercise.sets else { return }
        weightTexts = (0..<exercise.sets).map { setIndex in
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
        loadPreviousWeights()
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
                note: "",
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
                    Circle()
                        .stroke(
                            isCompleted ? BulkUpColors.accent : BulkUpColors.textTertiary.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)

                    if isCompleted {
                        Circle()
                            .fill(BulkUpColors.accent.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(BulkUpColors.accent)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)

                Text(mealType.capitalized.replacingOccurrences(of: "_", with: " "))
                    .font(BulkUpFont.body())
                    .foregroundColor(isCompleted ? BulkUpColors.textTertiary : BulkUpColors.textPrimary)
                    .strikethrough(isCompleted, color: BulkUpColors.textTertiary)

                Spacer()

                if !time.isEmpty {
                    Text(time)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)
                        .fontDesign(.monospaced)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayView()
        .environmentObject(AuthManager.shared)
}
