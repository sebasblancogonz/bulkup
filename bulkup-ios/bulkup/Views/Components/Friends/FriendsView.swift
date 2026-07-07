//
//  FriendsView.swift
//  bulkup
//
//  Friends leaderboard and streak tracking
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject private var friendsManager = FriendsManager.shared

    @State private var showingAddFriend = false
    @State private var showingMyCode = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                myStreakBanner

                todayCompletionCard

                leaderboardSection
            }
            .padding()
        }
        .background(BulkUpColors.background.ignoresSafeArea())
        .navigationTitle("Amigos")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
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
        .sheet(isPresented: $showingAddFriend) {
            AddFriendView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingMyCode) {
            MyFriendCodeView()
        }
        .onAppear {
            Task {
                await friendsManager.loadLeaderboard()
                await friendsManager.loadTodayStatus()
            }
        }
        .refreshable {
            await friendsManager.loadLeaderboard()
            await friendsManager.loadTodayStatus()
        }
    }

    // MARK: - My Streak Banner

    private var myStreakBanner: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.xl) {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(BulkUpColors.accent)
                            .font(BulkUpFont.sectionHeader())
                        Text("\(friendsManager.myStreak?.currentStreak ?? 0)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(BulkUpColors.textPrimary)
                    }
                    Text("Racha actual")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(friendsManager.myStreak?.longestStreak ?? 0)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text("Mejor racha")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(friendsManager.myStreak?.totalDays ?? 0)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text("Días total")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accentCardStyle(color: BulkUpColors.accent)
    }

    // MARK: - Today Completion

    private var todayCompletionCard: some View {
        Button {
            guard let userId = authManager.user?.id else { return }
            Task {
                await friendsManager.toggleTodayCompletion(
                    userId: userId,
                    planId: nil,
                    dayName: nil
                )
            }
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: friendsManager.todayCompleted ? "checkmark.circle.fill" : "circle")
                    .font(BulkUpFont.sectionHeader())
                    .foregroundColor(friendsManager.todayCompleted ? BulkUpColors.success : BulkUpColors.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(friendsManager.todayCompleted ? "Entrenamiento completado" : "Marcar entrenamiento de hoy")
                        .font(BulkUpFont.body())
                        .fontWeight(.semibold)
                        .foregroundColor(BulkUpColors.textPrimary)
                    Text(todayDateString())
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }

                Spacer()

                if friendsManager.todayCompleted {
                    Image(systemName: "flame.fill")
                        .foregroundColor(BulkUpColors.accent)
                }
            }
            .flatCardStyle()
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(BulkUpColors.accent)
                Text("Ranking")
                    .sectionHeader()
                Spacer()
            }
            .padding(.horizontal, 4)

            if friendsManager.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if friendsManager.friends.isEmpty {
                emptyFriendsState
            } else {
                // My entry
                if let myStreak = friendsManager.myStreak {
                    leaderboardRow(
                        rank: calculateMyRank(),
                        name: authManager.user?.name ?? "Yo",
                        imageURL: authManager.user?.safeProfileImageURL,
                        streak: myStreak.currentStreak,
                        isMe: true
                    )
                }

                // Friends
                ForEach(Array(friendsManager.friends.enumerated()), id: \.element.id) { index, friend in
                    leaderboardRow(
                        rank: calculateFriendRank(index: index),
                        name: friend.name,
                        imageURL: friend.profileImageURL,
                        streak: friend.currentStreak,
                        isMe: false
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await friendsManager.removeFriend(friendId: friend.userId)
                            }
                        } label: {
                            Label("Eliminar amigo", systemImage: "person.badge.minus")
                        }
                    }
                }
            }
        }
    }

    private var emptyFriendsState: some View {
        EmptyStateView(
            icon: "person.2.slash",
            title: "Sin amigos todavía",
            subtitle: "Comparte tu código o agrega el de un amigo para empezar a competir",
            color: BulkUpColors.accent,
            actionTitle: "Mi Código",
            actionIcon: "person.text.rectangle",
            action: { showingMyCode = true },
            secondaryActionTitle: "Agregar",
            secondaryActionIcon: "person.badge.plus",
            secondaryAction: { showingAddFriend = true }
        )
    }

    private func leaderboardRow(rank: Int, name: String, imageURL: String?, streak: Int, isMe: Bool) -> some View {
        HStack(spacing: Spacing.md) {
            // Rank
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(rank <= 3 ? BulkUpColors.accent : BulkUpColors.textSecondary)
                .frame(width: 32)

            // Avatar
            if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    avatarPlaceholder(name: name)
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                avatarPlaceholder(name: name)
            }

            // Name
            Text(name)
                .font(BulkUpFont.body())
                .fontWeight(isMe ? .bold : .medium)
                .foregroundColor(BulkUpColors.textPrimary)
                .lineLimit(1)

            if isMe {
                Text("(tú)")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            Spacer()

            // Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(streak > 0 ? BulkUpColors.accent : BulkUpColors.textTertiary)
                    .font(BulkUpFont.caption())
                Text("\(streak)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(BulkUpColors.textPrimary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(isMe ? BulkUpColors.accent.opacity(0.1) : BulkUpColors.surfaceElevated)
        )
    }

    private func avatarPlaceholder(name: String) -> some View {
        ZStack {
            Circle()
                .fill(BulkUpColors.accent.opacity(0.3))
                .frame(width: 36, height: 36)

            Text(name.prefix(1).uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(BulkUpColors.accent)
        }
    }

    // MARK: - Helpers

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

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d 'de' MMMM"
        formatter.locale = LanguageManager.shared.locale
        return formatter.string(from: Date()).capitalized
    }
}
