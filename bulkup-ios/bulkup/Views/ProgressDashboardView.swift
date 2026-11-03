//
//  ProgressDashboardView.swift
//  bulkup
//
//  Progress: the week as one strip of numbers, then the body, the records and
//  the ranking as three lifted slabs of rows. Operate, not a scoreboard.
//

import SwiftUI

struct ProgressDashboardView: View {
    @EnvironmentObject var authManager: AuthManager

    @ObservedObject private var bodyManager = BodyMeasurementsManager.shared
    @ObservedObject private var mealManager = MealTrackingManager.shared
    @ObservedObject private var rmManager = RMManager.shared
    @ObservedObject private var friendsManager = FriendsManager.shared
    @ObservedObject private var trainingManager = TrainingManager.shared
    @ObservedObject private var dietManager = DietManager.shared
    @ObservedObject private var storeKit = StoreKitManager.shared

    @State private var showingAddFriend = false
    @State private var selectedFriend: FriendProfile?
    @State private var showingMyCode = false
    @State private var showingSubscription = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sectionGap) {
                    header
                    weekStrip

                    if storeKit.isSubscribed {
                        bodySlab
                        recordsSlab
                        rankingSlab
                    } else {
                        lockedSlab
                        SubscriptionRequiredView(
                            onSubscribe: { showingSubscription = true },
                            title: "Cuerpo, récords y ranking",
                            subtitle: "Medidas corporales, récords personales y ranking con amigos, en el mismo sitio que tu semana.",
                            features: [
                                "Seguimiento de composición corporal",
                                "Récords personales (RM)",
                                "Ranking y competencia con amigos",
                            ],
                            compact: true
                        )
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xl)
            }
            .background(BulkUpGround())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView().environmentObject(authManager)
            }
            .sheet(item: $selectedFriend) { friend in
                FriendProfileView(friend: friend)
            }
            .sheet(isPresented: $showingMyCode) {
                MyFriendCodeView()
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView().environmentObject(authManager)
            }
            .task { await loadAllData() }
            .refreshable { await loadAllData() }
        }
    }

    // MARK: - Data

    private func loadAllData() async {
        #if DEBUG
        if DesignPreview.isActive { return }
        #endif
        guard let userId = authManager.user?.id else { return }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await bodyManager.loadLatestMeasurements(userId: userId) }
            group.addTask { await bodyManager.loadMeasurementsHistory(userId: userId) }
            group.addTask { await mealManager.loadComplianceStats(userId: userId) }
            group.addTask { await rmManager.loadInitialDataWithCache(token: "") }
            group.addTask { await friendsManager.loadLeaderboard() }
            group.addTask { await friendsManager.loadTodayStatus() }
            group.addTask { await friendsManager.loadMyStreak() }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Progreso")
                .titleVoice(.largeTitle)
                .foregroundColor(BulkUpColors.textPrimary)
            Text(weekRangeText)
                .font(BulkUpFont.numeric(.subheadline))
                .foregroundColor(BulkUpColors.textSecondary)
        }
    }

    /// "Semana del 2 al 8 nov"
    private var weekRangeText: String {
        var cal = Calendar(identifier: .iso8601)
        cal.locale = LanguageManager.shared.locale
        let today = Date()
        let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        let end = cal.date(byAdding: .day, value: 6, to: start) ?? today
        let sameMonth = cal.component(.month, from: start) == cal.component(.month, from: end)
        let day = DateFormatter()
        day.locale = LanguageManager.shared.locale
        day.dateFormat = sameMonth ? "d" : "d MMM"
        let dayMonth = DateFormatter()
        dayMonth.locale = LanguageManager.shared.locale
        dayMonth.dateFormat = "d MMM"
        return String(format: NSLocalizedString("Semana del %@ al %@", comment: ""),
                      day.string(from: start), dayMonth.string(from: end))
    }

    // MARK: - This week

    private var workoutsTotal: Int { trainingManager.trainingData.count }
    private var workoutsDone: Int { trainingManager.trainingData.filter { isDayCompleted($0) }.count }
    private var streak: Int { friendsManager.myStreak?.currentStreak ?? 0 }
    private var longestStreak: Int { friendsManager.myStreak?.longestStreak ?? 0 }

    private var weeklyCompliancePercent: Double? {
        let expected = DietCompliance.expectedMealsLast7(dietData: dietManager.dietData)
        return DietCompliance.percent(completedLast7: mealManager.weeklyCompletedMeals, expectedLast7: expected)
    }

    private var weekStrip: some View {
        StatsStrip(cells: [
            StatCell(
                value: workoutsTotal > 0 ? "\(workoutsDone)/\(workoutsTotal)" : "—",
                label: "Entrenos",
                detail: workoutsTotal > 0 ? nil : NSLocalizedString("Sin plan activo", comment: ""),
                progress: workoutsTotal > 0 ? Double(workoutsDone) / Double(workoutsTotal) : nil
            ),
            StatCell(
                value: weeklyCompliancePercent.map { "\(Int($0.rounded())) %" } ?? "—",
                label: "Comidas hechas",
                detail: weeklyCompliancePercent == nil ? NSLocalizedString("Sin plan activo", comment: "") : nil,
                progress: weeklyCompliancePercent.map { $0 / 100 }
            ),
            StatCell(
                value: "\(streak)",
                label: "Entrenos seguidos",
                detail: longestStreak > streak
                    ? String(format: NSLocalizedString("Mejor racha %lld", comment: ""), longestStreak)
                    : (streak > 0 ? NSLocalizedString("Tu mejor racha", comment: "") : nil),
                progress: longestStreak > 0 ? Double(streak) / Double(longestStreak) : nil
            ),
        ])
    }

    // MARK: - Body

    private var bodySlab: some View {
        NavigationLink(destination: BodyMeasurementsView().environmentObject(authManager)) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Text("Cuerpo")
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)
                    Spacer()
                    if let m = bodyManager.currentMeasurements {
                        Text(shortDate(m.fecha))
                            .font(BulkUpFont.numeric(.footnote))
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundColor(BulkUpColors.textTertiary)
                }

                if let m = bodyManager.currentMeasurements {
                    StatsStrip(cells: [
                        StatCell(value: BulkUpFormat.decimal(m.peso), unit: "kg", label: "Peso",
                                 detail: weightTrend.map { BulkUpFormat.signed($0) + " kg" }),
                        StatCell(value: bodyManager.bodyComposition.map { BulkUpFormat.decimal($0.bodyFatPercentage) } ?? "—",
                                 unit: "%", label: "Grasa"),
                        StatCell(value: bodyManager.bodyComposition.map { BulkUpFormat.decimal($0.leanMass) } ?? "—",
                                 unit: "kg", label: "Masa magra"),
                    ], bare: true)
                } else if bodyManager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                } else {
                    Text("Añade tu primera medida y verás aquí peso, grasa y masa magra.")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .slab()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Records

    private var recentRecords: [PersonalRecord] {
        Array(rmManager.bestRecords.sorted { $0.dateValue > $1.dateValue }.prefix(3))
    }

    private var recordsSlab: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Récords")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)
                Spacer()
                NavigationLink(destination: RMTrackerView().environmentObject(authManager)) {
                    Text(rmManager.bestRecords.isEmpty ? "Registrar" : "Ver todos")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(BulkUpColors.accentText)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.xs)

            if rmManager.isLoading && rmManager.bestRecords.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            } else if recentRecords.isEmpty {
                NavigationLink(destination: RMTrackerView().environmentObject(authManager)) {
                    SlabRow(showsSeparator: false) {
                        HStack {
                            Text("Registra tu primer récord")
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(.caption, weight: .semibold))
                                .foregroundColor(BulkUpColors.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                ForEach(Array(recentRecords.enumerated()), id: \.element.id) { i, record in
                    SlabRow(showsSeparator: i < recentRecords.count - 1) {
                        HStack(alignment: .center, spacing: Spacing.sm) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exerciseName(for: record.exerciseId))
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundColor(BulkUpColors.textPrimary)
                                    .lineLimit(1)
                                Text(formatRecordDate(record.date))
                                    .font(BulkUpFont.numeric(.footnote))
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }
                            Spacer(minLength: Spacing.sm)
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(BulkUpFormat.decimal(record.weight)) kg × \(record.reps)")
                                    .font(BulkUpFont.mono(17, weight: .semibold))
                                    .foregroundColor(BulkUpColors.textPrimary)
                                    .lineLimit(1)
                                if let rm = RMCalculator.calculateHybridRM(weight: record.weight, reps: record.reps) {
                                    Text("1RM \(BulkUpFormat.decimal(rm, fraction: 0)) kg")
                                        .font(BulkUpFont.numeric(.footnote))
                                        .foregroundColor(BulkUpColors.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .slab()
    }

    // MARK: - Ranking

    private var rankingSlab: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Ranking")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)
                Spacer()
                if !friendsManager.friends.isEmpty {
                    Text("Entrenos seguidos")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)

            if friendsManager.isLoading && friendsManager.friends.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            } else if friendsManager.friends.isEmpty {
                Text("Añade amigos para ver quién lleva más entrenos seguidos.")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.sm)
            } else {
                let rows = leaderboardRows
                ForEach(Array(rows.enumerated()), id: \.element.id) { i, row in
                    leaderboardRow(row, showsSeparator: i < rows.count - 1)
                }
            }

            // Footer links, in the row grammar of the exercise card.
            HStack(spacing: Spacing.md) {
                Button { showingMyCode = true } label: {
                    Text("Mi código")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(BulkUpColors.accentText)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button { showingAddFriend = true } label: {
                    Text("Añadir amigo")
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundColor(BulkUpColors.accentText)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .overlay(alignment: .top) {
                Rectangle().fill(BulkUpColors.line).frame(height: 1).padding(.leading, Spacing.md)
            }
        }
        .slab()
    }

    private struct LeaderboardRow: Identifiable {
        let id: String
        let rank: Int
        let name: String
        let imageURL: String?
        let streak: Int
        let isMe: Bool
    }

    /// Me plus the top five friends, sorted by streak, ranks shared on ties.
    private var leaderboardRows: [LeaderboardRow] {
        var all: [LeaderboardRow] = friendsManager.friends.map {
            LeaderboardRow(id: $0.id, rank: 0, name: $0.name, imageURL: $0.profileImageURL, streak: $0.currentStreak, isMe: false)
        }
        if let me = friendsManager.myStreak {
            all.append(LeaderboardRow(id: "me", rank: 0, name: authManager.user?.name ?? NSLocalizedString("Yo", comment: ""),
                                      imageURL: authManager.user?.safeProfileImageURL, streak: me.currentStreak, isMe: true))
        }
        let sorted = all.sorted { $0.streak > $1.streak }
        var ranked: [LeaderboardRow] = []
        for (i, row) in sorted.enumerated() {
            let rank = (i > 0 && sorted[i - 1].streak == row.streak) ? ranked[i - 1].rank : i + 1
            ranked.append(LeaderboardRow(id: row.id, rank: rank, name: row.name, imageURL: row.imageURL, streak: row.streak, isMe: row.isMe))
        }
        // Keep me visible even past the top six.
        let top = Array(ranked.prefix(6))
        if top.contains(where: \.isMe) { return top }
        return top + ranked.filter(\.isMe)
    }

    @ViewBuilder
    private func leaderboardRow(_ row: LeaderboardRow, showsSeparator: Bool) -> some View {
        let value = Text(String(format: NSLocalizedString("%lld entrenos seguidos", comment: ""), row.streak))
        if row.isMe {
            leaderboardRowContent(row, showsSeparator: showsSeparator)
                .accessibilityElement(children: .combine)
                .accessibilityValue(value)
        } else {
            Button {
                if let friend = friendsManager.friends.first(where: { $0.id == row.id }) {
                    selectedFriend = friend
                }
            } label: {
                leaderboardRowContent(row, showsSeparator: showsSeparator)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityValue(value)
            .accessibilityHint("Abre su perfil")
        }
    }

    private func leaderboardRowContent(_ row: LeaderboardRow, showsSeparator: Bool) -> some View {
        SlabRow(showsSeparator: showsSeparator, minHeight: 48) {
            HStack(spacing: Spacing.sm + 2) {
                Text("\(row.rank)")
                    .font(BulkUpFont.numeric(.footnote, weight: .semibold))
                    .foregroundColor(row.isMe ? BulkUpColors.textPrimary : BulkUpColors.textTertiary)
                    .frame(width: 18, alignment: .leading)
                ProfileAvatar(name: row.name, url: row.imageURL, size: 28)
                Text(row.name)
                    .font(.system(.subheadline, weight: row.isMe ? .semibold : .regular))
                    .foregroundColor(BulkUpColors.textPrimary)
                    .lineLimit(1)
                if row.isMe {
                    Text("(tú)")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                Spacer(minLength: Spacing.sm)
                Text("\(row.streak)")
                    .font(BulkUpFont.numeric(.subheadline, weight: .semibold))
                    .foregroundColor(BulkUpColors.textPrimary)
                if !row.isMe {
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, weight: .semibold))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
            }
        }
        .background(row.isMe ? BulkUpColors.surfaceElevated : Color.clear)
    }

    // MARK: - Locked (free tier)

    private var lockedSlab: some View {
        VStack(spacing: 0) {
            let items: [(LocalizedStringKey, String)] = [
                ("Medidas corporales", "scalemass"),
                ("Récords personales", "trophy"),
                ("Ranking con amigos", "person.2"),
            ]
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                Button { showingSubscription = true } label: {
                    SlabRow(showsSeparator: i < items.count - 1, minHeight: 48) {
                        HStack(spacing: Spacing.sm + 2) {
                            Image(systemName: "lock.fill")
                                .font(.system(.footnote, weight: .semibold))
                                .foregroundColor(BulkUpColors.textTertiary)
                                .frame(width: 20)
                            Text(item.0)
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.textPrimary)
                            Spacer()
                            Text("PRO")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundColor(BulkUpColors.onAccent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BulkUpColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            Image(systemName: "chevron.right")
                                .font(.system(.caption, weight: .semibold))
                                .foregroundColor(BulkUpColors.textTertiary)
                        }
                        .contentShape(Rectangle())
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .slab()
    }

    // MARK: - Helpers

    private var weightTrend: Double? {
        let history = bodyManager.measurementsHistory
        guard history.count >= 2 else { return nil }
        let sorted = history.sorted { $0.fecha > $1.fecha }
        return sorted[0].peso - sorted[1].peso
    }

    private func isDayCompleted(_ day: TrainingDay) -> Bool {
        for exercise in day.exercises {
            if trainingManager.hasWeightForExercise(exerciseName: exercise.name, day: day.day, week: trainingManager.selectedWeek) {
                return true
            }
        }
        return trainingManager.isDayCompleted(day: day.day)
    }

    private func exerciseName(for exerciseId: String) -> String {
        if let exercise = rmManager.getExerciseById(exerciseId) {
            return exercise.nameEs.isEmpty ? exercise.name : exercise.nameEs
        }
        return NSLocalizedString("Ejercicio", comment: "")
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = LanguageManager.shared.locale
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }

    private func formatRecordDate(_ dateString: String) -> String {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: dateString) { return formatDate(date) }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        guard let date = df.date(from: dateString) else { return dateString }
        return formatDate(date)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.locale = LanguageManager.shared.locale
        return f.string(from: date)
    }
}
