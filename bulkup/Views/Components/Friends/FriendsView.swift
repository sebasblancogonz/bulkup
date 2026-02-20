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
        .navigationTitle("Amigos")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { showingMyCode = true }) {
                        Image(systemName: "person.text.rectangle")
                            .font(.system(size: 16))
                    }
                    Button(action: { showingAddFriend = true }) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16))
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
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text("\(friendsManager.myStreak?.currentStreak ?? 0)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                    }
                    Text("Racha actual")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(friendsManager.myStreak?.longestStreak ?? 0)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("Mejor racha")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(friendsManager.myStreak?.totalDays ?? 0)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("Días total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.orange.opacity(0.15), .orange.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
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
            HStack(spacing: 12) {
                Image(systemName: friendsManager.todayCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(friendsManager.todayCompleted ? .green : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(friendsManager.todayCompleted ? "Entrenamiento completado" : "Marcar entrenamiento de hoy")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(todayDateString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if friendsManager.todayCompleted {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Ranking")
                    .font(.headline)
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
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("Sin amigos todavía")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Comparte tu código o agrega el de un amigo para empezar a competir")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button(action: { showingMyCode = true }) {
                    Label("Mi Código", systemImage: "person.text.rectangle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: { showingAddFriend = true }) {
                    Label("Agregar", systemImage: "person.badge.plus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
        }
        .padding(.vertical, 32)
    }

    private func leaderboardRow(rank: Int, name: String, imageURL: String?, streak: Int, isMe: Bool) -> some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(rank <= 3 ? .orange : .secondary)
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
                .font(.subheadline)
                .fontWeight(isMe ? .bold : .medium)
                .lineLimit(1)

            if isMe {
                Text("(tú)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(streak > 0 ? .orange : .gray)
                    .font(.caption)
                Text("\(streak)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isMe ? Color.orange.opacity(0.1) : Color(.systemGray6))
        )
    }

    private func avatarPlaceholder(name: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 36, height: 36)

            Text(name.prefix(1).uppercased())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.orange)
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

        // Friends are already sorted desc. Count how many are above this friend.
        let friendRank = index + 1
        if friend.currentStreak < myStreak {
            return friendRank + 1  // Push down by 1 for me
        } else if friend.currentStreak == myStreak {
            return friendRank >= myRank ? friendRank + 1 : friendRank
        }
        return friendRank
    }

    private func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d 'de' MMMM"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: Date()).capitalized
    }
}
