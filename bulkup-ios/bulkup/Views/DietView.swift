//
//  DietView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import SwiftData
import SwiftUI

struct DietView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dietManager: DietManager
    @ObservedObject private var mealTrackingManager = MealTrackingManager.shared
    @State private var currentDayIndex = 0
    @State private var expandedMeals: Set<Int> = []

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        Group {
            if dietManager.dietData.count == 1
                && dietManager.dietData[0].day == "Dieta Semanal"
            {
                singleDayContent(dietManager.dietData[0])
            } else if dietManager.dietData.count > 0 {
                multiDayContent
            }
        }
        .onAppear {
            clampDayIndex()
            loadTrackingForCurrentDay()
        }
    }

    // MARK: - Single Day (Weekly Plan)

    private func singleDayContent(_ day: DietDay) -> some View {
        let sortedMeals = day.meals.sorted { $0.orderIndex < $1.orderIndex }
        let completedCount = mealTrackingManager.todayTracking.filter { $0.completed }.count
        let allComplete = completedCount == sortedMeals.count && sortedMeals.count > 0

        return ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                dayHeader(
                    title: "Plan Semanal",
                    completedCount: completedCount,
                    totalCount: sortedMeals.count
                )
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.xl)

                // Celebration banner
                if allComplete {
                    celebrationBanner
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.bottom, Spacing.md)
                }

                // Daily macros
                dailyMacrosCard(day)
                    .padding(.bottom, Spacing.md)

                mealList(meals: sortedMeals, dayName: day.day)

                // Cheat meal section
                cheatMealSection(day)
                    .padding(.top, Spacing.md)

                if !day.supplements.isEmpty {
                    supplementsList(day.supplements)
                        .padding(.top, Spacing.sectionGap)
                }

                Color.clear.frame(height: 100)
            }
        }
        .refreshable {
            if let user = authManager.user {
                await dietManager.loadActiveDietPlan(userId: user.id)
                loadTrackingForCurrentDay()
            }
        }
    }

    // MARK: - Multi Day Content

    private var multiDayContent: some View {
        VStack(spacing: 0) {
            dayPillStrip

            TabView(selection: $currentDayIndex) {
                ForEach(Array(dietManager.dietData.enumerated()), id: \.offset) { index, day in
                    dayPageContent(day, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: currentDayIndex) { _, newIndex in
                guard !dietManager.dietData.isEmpty else { return }
                let clamped = min(max(newIndex, 0), dietManager.dietData.count - 1)
                if clamped != newIndex { currentDayIndex = clamped }
                expandedMeals = []
                loadTrackingForCurrentDay()
            }
            .onChange(of: dietManager.dietData) { _, _ in
                clampDayIndex()
                expandedMeals = []
            }
        }
    }

    // MARK: - Day Pill Strip

    private var dayPillStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(Array(dietManager.dietData.enumerated()), id: \.offset) { index, day in
                        let isSelected = index == currentDayIndex

                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                currentDayIndex = index
                            }
                        } label: {
                            Text(abbreviatedDayName(day.day))
                                .font(BulkUpFont.dataLabel())
                                .foregroundColor(isSelected ? BulkUpColors.onAccent : BulkUpColors.textSecondary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? BulkUpColors.accent : BulkUpColors.surfaceElevated)
                                )
                        }
                        .buttonStyle(.plain)
                        .id(index)
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, Spacing.sm)
            }
            .onChange(of: currentDayIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .background(BulkUpColors.background)
    }

    // MARK: - Day Page Content

    private func dayPageContent(_ day: DietDay, index: Int) -> some View {
        let sortedMeals = day.meals.sorted { $0.orderIndex < $1.orderIndex }
        let completedCount = mealTrackingManager.todayTracking.filter { $0.completed }.count
        let allComplete = completedCount == sortedMeals.count && sortedMeals.count > 0

        return ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                dayHeader(
                    title: LocalizedStringKey(formatDayName(day.day)),
                    completedCount: completedCount,
                    totalCount: sortedMeals.count,
                    subtitle: "Día \(index + 1) de \(dietManager.dietData.count)"
                )
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl)

                // Celebration banner
                if allComplete {
                    celebrationBanner
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.bottom, Spacing.md)
                }

                // Daily macros
                dailyMacrosCard(day)
                    .padding(.bottom, Spacing.md)

                mealList(meals: sortedMeals, dayName: day.day)

                // Cheat meal section
                cheatMealSection(day)
                    .padding(.top, Spacing.md)

                if !day.supplements.isEmpty {
                    supplementsList(day.supplements)
                        .padding(.top, Spacing.sectionGap)
                }

                Color.clear.frame(height: 100)
            }
        }
        .refreshable {
            if let user = authManager.user {
                await dietManager.loadActiveDietPlan(userId: user.id)
                loadTrackingForCurrentDay()
            }
        }
    }

    // MARK: - Day Header

    private func dayHeader(title: LocalizedStringKey, completedCount: Int, totalCount: Int, subtitle: LocalizedStringKey? = nil) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(BulkUpColors.textPrimary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }

            MetricRing(
                value: totalCount > 0 ? "\(completedCount)/\(totalCount)" : "—",
                label: "COMIDAS HOY",
                progress: totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0,
                size: 124,
                dimmed: totalCount == 0
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Progress Bar

    private func progressBar(completed: Int, total: Int) -> some View {
        let progress: CGFloat = total > 0 ? CGFloat(completed) / CGFloat(total) : 0

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(BulkUpColors.surfaceElevated)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(BulkUpColors.accent)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.easeOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Celebration Banner

    private var celebrationBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(BulkUpColors.accent)
            Text("¡Dieta completada hoy!")
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity)
    }

    // MARK: - Meal List

    private func mealList(meals: [Meal], dayName: String) -> some View {
        VStack(spacing: Spacing.sm) {
            ForEach(meals, id: \.id) { meal in
                let record = mealTrackingManager.trackingRecord(for: meal.order, date: todayDateString)
                let isExpanded = expandedMeals.contains(meal.order)

                MealCardView(
                    meal: meal,
                    trackingRecord: record,
                    isExpanded: isExpanded,
                    onToggleExpand: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if expandedMeals.contains(meal.order) {
                                expandedMeals.remove(meal.order)
                            } else {
                                expandedMeals.insert(meal.order)
                            }
                        }
                    },
                    onToggleCompletion: {
                        if let record = record {
                            Task {
                                if let userId = authManager.user?.id {
                                    await mealTrackingManager.toggleMealCompletion(record: record, userId: userId)
                                }
                            }
                        }
                    },
                    onNotesChanged: { notes in
                        if let record = record {
                            Task {
                                if let userId = authManager.user?.id {
                                    await mealTrackingManager.updateNotes(record: record, notes: notes, userId: userId)
                                }
                            }
                        }
                    }
                )
            }
        }
    }

    // MARK: - Supplements List

    private func supplementsList(_ supplements: [Supplement]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("SUPLEMENTOS")
                .font(BulkUpFont.sectionLabel())
                .tracking(1.5)
                .foregroundColor(BulkUpColors.textSecondary)
                .padding(.horizontal, Spacing.screenH)

            SupplementsView(supplements: supplements)
                .padding(.horizontal, Spacing.screenH)
        }
    }

    // MARK: - Daily Macros Card

    @ViewBuilder
    private func dailyMacrosCard(_ day: DietDay) -> some View {
        if day.hasMacros {
            VStack(alignment: .leading, spacing: 16) {
                MicroLabel("Macros diarios")

                // Calories hero
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(day.macroCalories)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text("kcal")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(BulkUpColors.textSecondary)
                    Spacer()
                }

                // Quiet macro stats — monochrome, no multicolor bars
                HStack(spacing: 0) {
                    macroStat(value: "\(day.macroProtein)", label: "Proteína")
                    macroStat(value: "\(day.macroCarbs)", label: "Carbos")
                    macroStat(value: "\(day.macroFat)", label: "Grasas")
                }
            }
            .whoopCard()
            .padding(.horizontal, Spacing.screenH)
        }
    }

    private func macroStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(BulkUpColors.textPrimary)
                Text("g")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }
            Text(LocalizedStringKey(label))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(BulkUpColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Cheat Meal Section

    @ViewBuilder
    private func cheatMealSection(_ day: DietDay) -> some View {
        if day.allowsCheatMeal {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Text("🍕")
                        .font(.system(size: 16))
                    Text("COMIDA LIBRE")
                        .font(BulkUpFont.sectionLabel())
                        .tracking(1.5)
                        .foregroundColor(BulkUpColors.textSecondary)
                    Spacer()
                    PillBadge(text: "Permitida", color: BulkUpColors.success, icon: "checkmark.circle")
                }

                Text("Registra lo que comiste en tu comida libre")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)

                TextEditor(text: $mealTrackingManager.cheatMealLog)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 60, maxHeight: 120)
                    .padding(Spacing.sm)
                    .background(BulkUpColors.surfaceElevated)
                    .cornerRadius(CornerRadius.small)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.small)
                            .stroke(BulkUpColors.textTertiary.opacity(0.15), lineWidth: 1)
                    )

                // Save button
                HStack {
                    Spacer()
                    Button {
                        if let userId = authManager.user?.id {
                            Task {
                                await mealTrackingManager.saveCheatMealLog(userId: userId, date: todayDateString)
                            }
                        }
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 11, weight: .medium))
                            Text("Guardar")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(BulkUpColors.accent)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(BulkUpColors.accent.opacity(0.1))
                        .cornerRadius(CornerRadius.small)
                    }
                    .disabled(mealTrackingManager.cheatMealLog.isEmpty)
                }
            }
            .padding(Spacing.md)
            .background(BulkUpColors.surface)
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(BulkUpColors.border, lineWidth: 0.5)
            )
            .padding(.horizontal, Spacing.screenH)
        }
    }

    // MARK: - Helpers

    private func clampDayIndex() {
        guard !dietManager.dietData.isEmpty else {
            currentDayIndex = 0
            return
        }
        currentDayIndex = min(currentDayIndex, dietManager.dietData.count - 1)
    }

    private func loadTrackingForCurrentDay() {
        guard let userId = authManager.user?.id else { return }

        let dayData: DietDay?
        if dietManager.dietData.count == 1 && dietManager.dietData[0].day == "Dieta Semanal" {
            dayData = dietManager.dietData.first
        } else if currentDayIndex < dietManager.dietData.count {
            dayData = dietManager.dietData[currentDayIndex]
        } else {
            dayData = dietManager.dietData.first
        }

        guard let day = dayData else { return }

        Task {
            await mealTrackingManager.loadTracking(
                userId: userId,
                date: todayDateString,
                dayName: day.day,
                planId: dietManager.dietPlanId,
                meals: day.meals
            )
        }
    }

    private func abbreviatedDayName(_ day: String) -> String {
        let norm = day.lowercased()
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_ES"))
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespaces)

        if norm.hasPrefix("dia") {
            let number = norm.filter { $0.isNumber }
            if !number.isEmpty {
                return "D\(number)"
            }
        }

        // Localized weekday (e.g. "Lunes"/"Monday") shortened to 3 letters.
        return String(WeekdayLabel.localized(day).prefix(3))
    }

    private func formatDayName(_ day: String) -> String {
        return WeekdayLabel.localized(day)
    }
}

// MARK: - Macro Bar

private struct MacroBar: View {
    let label: String
    let grams: Int
    let color: Color
    let total: Int

    private var caloriesFromMacro: Int {
        switch label {
        case "Grasas": return grams * 9
        default: return grams * 4
        }
    }

    private var percentage: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(caloriesFromMacro) / CGFloat(total)
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text("\(grams)g")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(BulkUpColors.textPrimary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * min(percentage, 1.0), height: 6)
                }
            }
            .frame(height: 6)

            Text(LocalizedStringKey(label))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(BulkUpColors.textTertiary)

            Text("\(Int(percentage * 100))%")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}
