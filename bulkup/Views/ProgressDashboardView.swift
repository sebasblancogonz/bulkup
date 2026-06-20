//
//  ProgressDashboardView.swift
//  bulkup
//
//  Unified progress dashboard aggregating all user metrics.
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
    @State private var showingMyCode = false
    @State private var showingSubscription = false
    @State private var showingRMTracker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sectionGap) {
                    // Free: Weekly summary and training progress
                    weeklySummaryCard

                    trainingProgressCard

                    mealComplianceCard

                    // Premium: Body stats, PR, Friends
                    if storeKit.isSubscribed {
                        bodyStatsCard

                        personalRecordsCard

                        friendsLeaderboardCard
                    } else {
                        // Gated premium sections
                        premiumProgressTeaser
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            .background(BulkUpColors.background.ignoresSafeArea())
            .navigationTitle("Progreso")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if storeKit.isSubscribed {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 12) {
                            Button(action: { showingMyCode = true }) {
                                Image(systemName: "person.text.rectangle")
                                    .font(.system(size: 16))
                                    .foregroundColor(BulkUpColors.accent)
                            }
                            Button(action: { showingAddFriend = true }) {
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 16))
                                    .foregroundColor(BulkUpColors.accent)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingMyCode) {
                MyFriendCodeView()
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
                    .environmentObject(authManager)
            }
            .task {
                await loadAllData()
            }
            .refreshable {
                await loadAllData()
            }
        }
    }

    // MARK: - Data Loading

    private func loadAllData() async {
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

    // MARK: - Section 1: Weekly Summary

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(BulkUpColors.accent)
                    .font(BulkUpFont.cardTitle())

                Text("Resumen Semanal")
                    .sectionHeader()

                Spacer()
            }

            HStack(spacing: 0) {
                // Training days
                VStack(spacing: 4) {
                    Text(weeklyTrainingText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(BulkUpColors.training)
                    Text("Entrenos")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(BulkUpColors.training.opacity(0.08))
                .cornerRadius(CornerRadius.small)

                Spacer().frame(width: 8)

                // Meal compliance
                VStack(spacing: 4) {
                    Text(weeklyComplianceText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(BulkUpColors.diet)
                    Text("Cumplimiento")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(BulkUpColors.diet.opacity(0.08))
                .cornerRadius(CornerRadius.small)

                Spacer().frame(width: 8)

                // Streak
                VStack(spacing: 4) {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(BulkUpColors.accent)
                            .font(.system(size: 12))
                        Text("\(friendsManager.myStreak?.currentStreak ?? 0)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(BulkUpColors.accent)
                    }
                    Text("Racha")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(BulkUpColors.accent.opacity(0.08))
                .cornerRadius(CornerRadius.small)
            }
        }
        .accentCardStyle(color: BulkUpColors.accent)
    }

    // MARK: - Premium Teaser

    private var premiumProgressTeaser: some View {
        VStack(spacing: Spacing.lg) {
            // Blurred preview of body stats
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(BulkUpColors.training)
                    Text("Medidas Corporales")
                        .font(BulkUpFont.cardTitle())
                        .fontWeight(.bold)
                        .foregroundColor(BulkUpColors.textPrimary)
                    Spacer()
                    Text("PRO")
                        .font(BulkUpFont.caption())
                        .fontWeight(.bold)
                        .foregroundColor(BulkUpColors.onAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(BulkUpColors.secondary)
                        .cornerRadius(4)
                }

                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text("--.- kg")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(BulkUpColors.training.opacity(0.3))
                        Text("Peso")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(BulkUpColors.training.opacity(0.05))
                    .cornerRadius(CornerRadius.small)

                    Spacer().frame(width: 8)

                    VStack(spacing: 4) {
                        Text("--.-%")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(BulkUpColors.accent.opacity(0.3))
                        Text("% Grasa")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(BulkUpColors.accent.opacity(0.05))
                    .cornerRadius(CornerRadius.small)

                    Spacer().frame(width: 8)

                    VStack(spacing: 4) {
                        Text("--.- kg")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(BulkUpColors.success.opacity(0.3))
                        Text("Masa Magra")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(BulkUpColors.success.opacity(0.05))
                    .cornerRadius(CornerRadius.small)
                }
            }
            .cardStyle()
            .opacity(0.6)

            // Blurred preview of PR
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(BulkUpColors.accent)
                    Text("Records Personales")
                        .font(BulkUpFont.cardTitle())
                        .fontWeight(.bold)
                        .foregroundColor(BulkUpColors.textPrimary)
                    Spacer()
                    Text("PRO")
                        .font(BulkUpFont.caption())
                        .fontWeight(.bold)
                        .foregroundColor(BulkUpColors.onAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(BulkUpColors.secondary)
                        .cornerRadius(4)
                }

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(BulkUpColors.textSecondary)
                        .font(BulkUpFont.caption())
                    Text("Registra y sigue tus PR con PRO")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
            .cardStyle()
            .opacity(0.6)

            // Blurred preview of friends
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(BulkUpColors.accent)
                    Text("Ranking")
                        .font(BulkUpFont.cardTitle())
                        .fontWeight(.bold)
                        .foregroundColor(BulkUpColors.textPrimary)
                    Spacer()
                    Text("PRO")
                        .font(BulkUpFont.caption())
                        .fontWeight(.bold)
                        .foregroundColor(BulkUpColors.onAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(BulkUpColors.secondary)
                        .cornerRadius(4)
                }

                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(BulkUpColors.textSecondary)
                        .font(BulkUpFont.caption())
                    Text("Compite con amigos con PRO")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
            .cardStyle()
            .opacity(0.6)

            // CTA
            SubscriptionRequiredView(
                onSubscribe: { showingSubscription = true },
                title: "Desbloquea el Progreso Completo",
                subtitle: "Medidas corporales, records personales y ranking con amigos",
                features: [
                    "Seguimiento de composicion corporal",
                    "Records personales (RM)",
                    "Ranking y competencia con amigos"
                ],
                compact: true
            )
        }
    }

    // MARK: - Section 2: Body Stats

    private var bodyStatsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(BulkUpColors.training)

                Text("Medidas Corporales")
                    .sectionHeader()

                Spacer()

                NavigationLink(destination: BodyMeasurementsView().environmentObject(authManager)) {
                    Text("Ver historial")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.accent)
                }
            }

            if let m = bodyManager.currentMeasurements {
                HStack(spacing: 0) {
                    // Weight + trend
                    VStack(spacing: 4) {
                        HStack(spacing: 3) {
                            Text(String(format: "%.1f", m.peso))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(BulkUpColors.training)
                            Text("kg")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                            if let trend = weightTrend {
                                Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(trend > 0 ? BulkUpColors.error : BulkUpColors.success)
                            }
                        }
                        Text("Peso")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(BulkUpColors.training.opacity(0.08))
                    .cornerRadius(CornerRadius.small)

                    Spacer().frame(width: 8)

                    // Body fat + trend
                    if let comp = bodyManager.bodyComposition {
                        VStack(spacing: 4) {
                            HStack(spacing: 3) {
                                Text(String(format: "%.1f", comp.bodyFatPercentage))
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(BulkUpColors.accent)
                                Text("%")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                                if let trend = bodyFatTrend {
                                    Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(trend > 0 ? BulkUpColors.error : BulkUpColors.success)
                                }
                            }
                            Text("% Grasa")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(BulkUpColors.accent.opacity(0.08))
                        .cornerRadius(CornerRadius.small)
                    }

                    Spacer().frame(width: 8)

                    // Lean mass
                    if let comp = bodyManager.bodyComposition {
                        VStack(spacing: 4) {
                            HStack(spacing: 3) {
                                Text(String(format: "%.1f", comp.leanMass))
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(BulkUpColors.success)
                                Text("kg")
                                    .font(BulkUpFont.caption())
                                    .foregroundColor(BulkUpColors.textSecondary)
                            }
                            Text("Masa Magra")
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(BulkUpColors.success.opacity(0.08))
                        .cornerRadius(CornerRadius.small)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(BulkUpColors.textSecondary)
                        .font(BulkUpFont.caption())
                    Text("Agrega tus medidas corporales para ver tu progreso")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Section 3: Training Progress

    private var trainingProgressCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(BulkUpColors.training)

                Text("Entrenamiento")
                    .sectionHeader()

                Spacer()
            }

            if !trainingManager.trainingData.isEmpty {
                // Active plan name
                if let firstDay = trainingManager.trainingData.first,
                   let _ = firstDay.planId {
                    Text("Plan activo")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                // This week's days
                let weekDays = trainingManager.trainingData
                HStack(spacing: 6) {
                    ForEach(weekDays, id: \.day) { day in
                        let isDone = isDayCompleted(day)
                        VStack(spacing: 4) {
                            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isDone ? BulkUpColors.success : BulkUpColors.textTertiary)
                                .font(.system(size: 16))
                            Text(dayAbbreviation(day.day))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(isDone ? BulkUpColors.textPrimary : BulkUpColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // Streak
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(BulkUpColors.accent)
                        .font(BulkUpFont.caption())
                    Text("Racha actual: \(friendsManager.myStreak?.currentStreak ?? 0) dias")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(BulkUpColors.textSecondary)
                        .font(BulkUpFont.caption())
                    Text("No hay plan de entrenamiento activo")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Section 4: Meal Compliance

    /// Weekly compliance: meals completed in the last 7 days vs. meals the active
    /// plan expects over those 7 days (single-template plans apply every day).
    /// nil when the plan expects no measurable meals → UI shows "—".
    private var weeklyCompliancePercent: Double? {
        let expected = DietCompliance.expectedMealsLast7(dietData: dietManager.dietData)
        return DietCompliance.percent(
            completedLast7: mealManager.weeklyCompletedMeals,
            expectedLast7: expected
        )
    }

    private var mealComplianceCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(BulkUpColors.diet)

                Text("Alimentacion")
                    .sectionHeader()

                Spacer()
            }

            if let stats = mealManager.complianceStats {
                HStack(spacing: 0) {
                    // Today
                    VStack(spacing: 4) {
                        Text(mealManager.todayComplianceSummary)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(BulkUpColors.diet)
                        Text("Hoy")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(BulkUpColors.diet.opacity(0.08))
                    .cornerRadius(CornerRadius.small)

                    Spacer().frame(width: 8)

                    // Weekly compliance (meals done vs. meals the plan expects over 7 days)
                    let weekly = weeklyCompliancePercent
                    let weeklyColor = (weekly ?? 0) >= 80 ? BulkUpColors.success : BulkUpColors.warning
                    VStack(spacing: 4) {
                        Text(weekly.map { String(format: "%.0f%%", $0) } ?? "—")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(weekly == nil ? BulkUpColors.textSecondary : weeklyColor)
                        Text("Semanal")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background((weekly == nil ? BulkUpColors.textSecondary : weeklyColor).opacity(0.08))
                    .cornerRadius(CornerRadius.small)

                    Spacer().frame(width: 8)

                    // Streak
                    VStack(spacing: 4) {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(BulkUpColors.accent)
                                .font(.system(size: 12))
                            Text("\(stats.currentStreak)")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(BulkUpColors.accent)
                        }
                        Text("Racha")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(BulkUpColors.accent.opacity(0.08))
                    .cornerRadius(CornerRadius.small)
                }
            } else if !dietManager.dietData.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(BulkUpColors.textSecondary)
                        .font(BulkUpFont.caption())
                    Text("Marca tus comidas para ver estadisticas de cumplimiento")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(BulkUpColors.textSecondary)
                        .font(BulkUpFont.caption())
                    Text("No hay plan de dieta activo")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Section 5: Personal Records

    private var personalRecordsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(BulkUpColors.accent)

                Text("Records Personales")
                    .sectionHeader()

                Spacer()

                Button { showingRMTracker = true } label: {
                    Text(rmManager.bestRecords.isEmpty ? "Registrar" : "Ver todos")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.accent)
                }
            }

            if rmManager.bestRecords.isEmpty {
                Button { showingRMTracker = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(BulkUpColors.accent)
                            .font(BulkUpFont.caption())
                        Text("Registra tus levantamientos")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                let recentRecords = Array(
                    rmManager.bestRecords
                        .sorted { $0.dateValue > $1.dateValue }
                        .prefix(3)
                )

                ForEach(recentRecords) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exerciseName(for: record.exerciseId))
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.textPrimary)
                                .lineLimit(1)
                            Text(formatRecordDate(record.date))
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                        }

                        Spacer()

                        Text(String(format: "%.1f kg", record.weight))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(BulkUpColors.accent)
                    }
                    .padding(.vertical, 4)

                    if record.id != recentRecords.last?.id {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
        .sheet(isPresented: $showingRMTracker) {
            RMTrackerView()
                .environmentObject(authManager)
        }
    }

    // MARK: - Section 6: Friends & Leaderboard

    private var friendsLeaderboardCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(BulkUpColors.accent)

                Text("Ranking")
                    .sectionHeader()

                Spacer()
            }

            if friendsManager.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if friendsManager.friends.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(BulkUpColors.textSecondary)
                        .font(BulkUpFont.caption())
                    Text("Agrega amigos para ver el ranking")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                HStack(spacing: 12) {
                    Button(action: { showingMyCode = true }) {
                        Label("Mi Codigo", systemImage: "person.text.rectangle")
                            .font(BulkUpFont.dataLabel())
                            .foregroundColor(BulkUpColors.accent)
                    }

                    Button(action: { showingAddFriend = true }) {
                        Label("Agregar", systemImage: "person.badge.plus")
                            .font(BulkUpFont.dataLabel())
                            .foregroundColor(BulkUpColors.accent)
                    }
                }
                .padding(.top, 4)
            } else {
                // My entry
                if let myStreak = friendsManager.myStreak {
                    compactLeaderboardRow(
                        rank: calculateMyRank(),
                        name: authManager.user?.name ?? "Yo",
                        imageURL: authManager.user?.safeProfileImageURL,
                        streak: myStreak.currentStreak,
                        isMe: true
                    )
                }

                // Top 5 friends
                let topFriends = Array(friendsManager.friends.prefix(5))
                ForEach(Array(topFriends.enumerated()), id: \.element.id) { index, friend in
                    compactLeaderboardRow(
                        rank: calculateFriendRank(index: index),
                        name: friend.name,
                        imageURL: friend.profileImageURL,
                        streak: friend.currentStreak,
                        isMe: false
                    )
                }

                if friendsManager.friends.count > 5 {
                    HStack {
                        Spacer()
                        Text("Ver leaderboard completo")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.accent)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Compact Leaderboard Row

    private func compactLeaderboardRow(rank: Int, name: String, imageURL: String?, streak: Int, isMe: Bool) -> some View {
        HStack(spacing: 10) {
            Text("#\(rank)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(rank <= 3 ? BulkUpColors.accent : BulkUpColors.textSecondary)
                .frame(width: 28)

            if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    avatarPlaceholder(name: name)
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
            } else {
                avatarPlaceholder(name: name)
            }

            Text(name)
                .font(BulkUpFont.body())
                .fontWeight(isMe ? .bold : .medium)
                .foregroundColor(BulkUpColors.textPrimary)
                .lineLimit(1)

            if isMe {
                Text("(tu)")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            Spacer()

            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .foregroundColor(streak > 0 ? BulkUpColors.accent : BulkUpColors.textTertiary)
                    .font(.system(size: 11))
                Text("\(streak)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(BulkUpColors.textPrimary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(isMe ? BulkUpColors.accent.opacity(0.1) : BulkUpColors.surfaceElevated)
        )
    }

    private func avatarPlaceholder(name: String) -> some View {
        ZStack {
            Circle()
                .fill(BulkUpColors.accent.opacity(0.3))
                .frame(width: 28, height: 28)

            Text(name.prefix(1).uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(BulkUpColors.accent)
        }
    }

    // MARK: - Helpers

    private var weeklyTrainingText: String {
        let totalDays = trainingManager.trainingData.count
        guard totalDays > 0 else { return "0/0" }
        let completedDays = trainingManager.trainingData.filter { isDayCompleted($0) }.count
        return String(format: String(localized: "%1$d/%2$d dias"), completedDays, totalDays)
    }

    private var weeklyComplianceText: String {
        if let stats = mealManager.complianceStats {
            return String(format: "%.0f%%", stats.complianceRate * 100)
        }
        return "--"
    }

    private var weightTrend: Double? {
        let history = bodyManager.measurementsHistory
        guard history.count >= 2 else { return nil }
        let sorted = history.sorted { $0.fecha > $1.fecha }
        return sorted[0].peso - sorted[1].peso
    }

    private var bodyFatTrend: Double? {
        return nil
    }

    private func isDayCompleted(_ day: TrainingDay) -> Bool {
        for exercise in day.exercises {
            if trainingManager.hasWeightForExercise(
                exerciseName: exercise.name,
                day: day.day,
                week: trainingManager.selectedWeek
            ) {
                return true
            }
        }
        return false
    }

    private func dayAbbreviation(_ day: String) -> String {
        let abbrevs: [String: String] = [
            "lunes": "L",
            "martes": "M",
            "miercoles": "X",
            "miércoles": "X",
            "jueves": "J",
            "viernes": "V",
            "sabado": "S",
            "sábado": "S",
            "domingo": "D"
        ]
        return abbrevs[day.lowercased()] ?? String(day.prefix(1).uppercased())
    }

    private func exerciseName(for exerciseId: String) -> String {
        if let exercise = rmManager.getExerciseById(exerciseId) {
            return exercise.nameEs.isEmpty ? exercise.name : exercise.nameEs
        }
        return "Ejercicio"
    }

    private func formatRecordDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        guard let date = isoFormatter.date(from: dateString) else {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            guard let date = df.date(from: dateString) else { return dateString }
            return formatDate(date)
        }
        return formatDate(date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = LanguageManager.shared.locale
        return formatter.string(from: date)
    }

    private func calculateMyRank() -> Int {
        let myStreak = friendsManager.myStreak?.currentStreak ?? 0
        let higher = friendsManager.friends.filter { $0.currentStreak > myStreak }.count
        return higher + 1
    }

    private func calculateFriendRank(index: Int) -> Int {
        let myStreak = friendsManager.myStreak?.currentStreak ?? 0
        let friend = friendsManager.friends[index]
        let myRank = calculateMyRank()
        let friendRank = index + 1
        if friend.currentStreak < myStreak {
            return friendRank + 1
        } else if friend.currentStreak == myStreak {
            return friendRank >= myRank ? friendRank + 1 : friendRank
        }
        return friendRank
    }
}
