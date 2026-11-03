//
//  DietView.swift
//  bulkup
//
//  The day's meals as a checklist read at the table: the next meal steps
//  forward, the rest wait. Graphite & Voltage, light instead of lines.
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

    /// One plan for every day of the week ("Dieta Semanal").
    private var isWeeklyPlan: Bool {
        dietManager.dietData.count == 1 && dietManager.dietData[0].day == "Dieta Semanal"
    }

    var body: some View {
        Group {
            if isWeeklyPlan {
                dayPage(dietManager.dietData[0], index: nil)
            } else if dietManager.dietData.count > 0 {
                multiDayContent
            }
        }
        // The page container keeps its pages inside the safe area, so the meal
        // list stopped above the floating tab bar instead of scrolling under it
        // like Entreno. Each page already pads its own bottom.
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            clampDayIndex()
            loadTrackingForCurrentDay()
        }
    }

    // MARK: - Multi Day Content

    private var multiDayContent: some View {
        VStack(spacing: 0) {
            if dietManager.dietData.count > 1 {
                dayStrip
                    .padding(.horizontal, Spacing.screenH)
                    .padding(.bottom, Spacing.md)

                TabView(selection: $currentDayIndex) {
                    ForEach(Array(dietManager.dietData.enumerated()), id: \.offset) { index, day in
                        dayPage(day, index: index)
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
            } else {
                // One day needs no pager, and a single-page pager that extends
                // under the tab bar hides the day header.
                dayPage(dietManager.dietData[0], index: 0)
            }
        }
        .onChange(of: dietManager.dietData) { _, _ in
            clampDayIndex()
            expandedMeals = []
        }
    }

    // MARK: - Day strip (lifted slab, selected day a lime square)

    private var dayStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(Array(dietManager.dietData.enumerated()), id: \.offset) { index, day in
                        let isSelected = index == currentDayIndex

                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                currentDayIndex = index
                            }
                        } label: {
                            Text(abbreviatedDayName(day.day))
                                .font(.system(.subheadline, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? BulkUpColors.onAccent : BulkUpColors.textSecondary)
                                .frame(minWidth: 44, minHeight: 36)
                                .padding(.horizontal, Spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                                        .fill(isSelected ? BulkUpColors.accent : Color.clear)
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(index)
                    }
                }
                .padding(Spacing.xs)
            }
            .onChange(of: currentDayIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .lift()
    }

    // MARK: - Day page

    private func dayPage(_ day: DietDay, index: Int?) -> some View {
        let sortedMeals = day.meals.sorted { $0.orderIndex < $1.orderIndex }
        let completedCount = mealTrackingManager.todayTracking.filter { $0.completed }.count
        let allComplete = completedCount == sortedMeals.count && sortedMeals.count > 0
        let title: String = index == nil
            ? NSLocalizedString("Plan semanal", comment: "")
            : formatDayName(day.day)
        let subtitle: String? = (index != nil && dietManager.dietData.count > 1)
            ? String(format: NSLocalizedString("Día %lld de %lld", comment: ""), (index ?? 0) + 1, dietManager.dietData.count)
            : nil

        return ScrollViewReader { proxy in
          ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                dayProgress(title: title, subtitle: subtitle,
                            completed: completedCount, total: sortedMeals.count, allComplete: allComplete)
                    .padding(.horizontal, Spacing.screenH)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.lg)

                if day.hasMacros {
                    macroStrip(day)
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.bottom, Spacing.lg)
                }

                mealList(meals: sortedMeals, dayName: day.day)
                    .padding(.horizontal, Spacing.screenH)
                    .id("meals")

                if day.allowsCheatMeal {
                    cheatMealSection
                        .padding(.horizontal, Spacing.screenH)
                        .padding(.top, Spacing.lg)
                }

                if !day.supplements.isEmpty {
                    supplementsList(day.supplements)
                        .padding(.top, Spacing.sectionGap)
                }

                Color.clear.frame(height: 100).id("bottom")
            }
          }
          .onAppear {
              #if DEBUG
              // Design review: open the next meal and show the lower half of the page.
              if DesignPreview.screen == "diet-detail" {
                  expandedMeals = [sortedMeals.indices.contains(2) ? sortedMeals[2].order : 0]
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                      withAnimation { proxy.scrollTo("meals", anchor: .top) }
                  }
              }
              #endif
          }
        }
        .refreshable {
            if let user = authManager.user {
                await dietManager.loadActiveDietPlan(userId: user.id)
                loadTrackingForCurrentDay()
            }
        }
    }

    // MARK: - Day progress (title, count, lime rule → sky when done)

    private func dayProgress(title: String, subtitle: String?, completed: Int, total: Int, allComplete: Bool) -> some View {
        let progress: CGFloat = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundColor(BulkUpColors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(BulkUpFont.numeric(.footnote))
                            .foregroundColor(BulkUpColors.textTertiary)
                    }
                }
                Spacer(minLength: Spacing.md)
                if total > 0 {
                    Text(allComplete ? "Dieta completada hoy" : "\(completed)/\(total) comidas")
                        .font(BulkUpFont.numeric(.subheadline, weight: .semibold))
                        .foregroundColor(allComplete ? BulkUpColors.complete : BulkUpColors.textSecondary)
                        .contentTransition(.numericText())
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(BulkUpColors.line)
                    Rectangle()
                        .fill(allComplete ? BulkUpColors.complete : BulkUpColors.accent)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 3)
        }
    }

    // MARK: - Macros: one lifted strip of evidence

    private static let kcalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = LanguageManager.shared.locale
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private func macroStrip(_ day: DietDay) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(Self.kcalFormatter.string(from: NSNumber(value: day.macroCalories)) ?? "\(day.macroCalories)")
                    .font(BulkUpFont.mono(22, weight: .semibold, relativeTo: .title2))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("kcal")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            macroDivider
            macroCell(grams: day.macroProtein, label: "Proteína")
            macroDivider
            macroCell(grams: day.macroCarbs, label: "Carbos")
            macroDivider
            macroCell(grams: day.macroFat, label: "Grasas")
        }
        .padding(Spacing.md)
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .lift()
    }

    private var macroDivider: some View {
        Rectangle()
            .fill(BulkUpColors.line)
            .frame(width: 1, height: 36)
            .padding(.trailing, Spacing.sm + 4)
    }

    private func macroCell(grams: Int, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(grams) g")
                .font(BulkUpFont.numeric(.headline, weight: .semibold))
                .foregroundColor(BulkUpColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Meal list: one slab, the next meal raised

    private func mealList(meals: [Meal], dayName: String) -> some View {
        let nextOrder = meals.first { meal in
            !(mealTrackingManager.trackingRecord(for: meal.order, date: todayDateString)?.completed ?? false)
        }?.order

        return VStack(spacing: 0) {
            ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                let record = mealTrackingManager.trackingRecord(for: meal.order, date: todayDateString)
                let isExpanded = expandedMeals.contains(meal.order)

                MealCardView(
                    meal: meal,
                    trackingRecord: record,
                    isExpanded: isExpanded,
                    isNext: meal.order == nextOrder,
                    showsSeparator: index < meals.count - 1,
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
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .lift()
    }

    // MARK: - Supplements

    private func supplementsList(_ supplements: [Supplement]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Suplementos")
                .font(.system(.headline, weight: .semibold))
                .foregroundColor(BulkUpColors.textPrimary)
                .padding(.horizontal, Spacing.screenH)

            SupplementsView(supplements: supplements)
                .padding(.horizontal, Spacing.screenH)
        }
    }

    // MARK: - Cheat meal (quiet lifted card)

    private var cheatMealSection: some View {
        let isEmpty = mealTrackingManager.cheatMealLog.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Comida libre")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                Text("Permitida hoy · anota qué comiste")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            TextEditor(text: $mealTrackingManager.cheatMealLog)
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 72, maxHeight: 140)
                .padding(Spacing.sm)
                .background(BulkUpColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))

            HStack {
                Spacer()
                Button {
                    if let userId = authManager.user?.id {
                        Task {
                            await mealTrackingManager.saveCheatMealLog(userId: userId, date: todayDateString)
                        }
                    }
                } label: {
                    Text("Guardar")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(BulkUpColors.textPrimary)
                        .padding(.horizontal, Spacing.md)
                        .frame(minHeight: 36)
                        .background(BulkUpColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                }
                .disabled(isEmpty)
                .opacity(isEmpty ? 0.5 : 1)
            }
        }
        .padding(Spacing.md)
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .lift()
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
        if isWeeklyPlan {
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
