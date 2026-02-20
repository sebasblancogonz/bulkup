//
//  FriendsManager.swift
//  bulkup
//
//  Friends & streak management
//

import Foundation

@MainActor
class FriendsManager: ObservableObject {
    static let shared = FriendsManager()

    @Published var friends: [FriendProfile] = []
    @Published var myStreak: TrainingStreakResponse?
    @Published var myFriendCode: String?
    @Published var todayCompleted: Bool = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    private init() {}

    // MARK: - Friend Code

    func loadFriendCode() async {
        do {
            myFriendCode = try await apiService.getMyFriendCode()
        } catch {
            errorMessage = "Error cargando código de amigo"
        }
    }

    // MARK: - Leaderboard

    func loadLeaderboard() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let leaderboard = try await apiService.getLeaderboard()
            friends = leaderboard.friends
            myStreak = leaderboard.myStreak
        } catch {
            errorMessage = "Error cargando ranking"
        }
    }

    // MARK: - Friends

    func addFriend(userId: String, code: String) async -> Bool {
        do {
            _ = try await apiService.addFriend(userId: userId, friendCode: code)
            await loadLeaderboard()
            return true
        } catch {
            errorMessage = "Código inválido o ya son amigos"
            return false
        }
    }

    func removeFriend(friendId: String) async {
        do {
            try await apiService.removeFriend(friendId: friendId)
            friends.removeAll { $0.userId == friendId }
        } catch {
            errorMessage = "Error eliminando amigo"
        }
    }

    // MARK: - Workout Completion

    func toggleTodayCompletion(userId: String, planId: String?, dayName: String?) async {
        let today = formatDate(Date())

        if todayCompleted {
            do {
                try await apiService.uncompleteWorkout(date: today)
                todayCompleted = false
            } catch {
                errorMessage = "Error desmarcando entrenamiento"
            }
        } else {
            do {
                try await apiService.completeWorkout(
                    userId: userId,
                    date: today,
                    planId: planId,
                    dayName: dayName
                )
                todayCompleted = true
            } catch {
                errorMessage = "Error marcando entrenamiento"
            }
        }

        await loadMyStreak()
    }

    func loadTodayStatus() async {
        let today = formatDate(Date())
        do {
            todayCompleted = try await apiService.getCompletionStatus(date: today)
        } catch {
            // Silently fail
        }
    }

    func loadMyStreak() async {
        do {
            myStreak = try await apiService.getMyStreak()
        } catch {
            // Silently fail
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
