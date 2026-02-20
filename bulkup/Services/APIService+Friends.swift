//
//  APIService+Friends.swift
//  bulkup
//
//  Friends & Streak API extensions
//

import Foundation

extension APIService {

    // MARK: - Friend Code

    func getMyFriendCode() async throws -> String {
        let response: APIResponse<FriendCodeResponse> = try await request(
            endpoint: "friends/code",
            method: .GET
        )
        guard let data = response.data else {
            throw APIError.noData
        }
        return data.friendCode
    }

    // MARK: - Friends Management

    func addFriend(userId: String, friendCode: String) async throws -> AddFriendResponse {
        let request = AddFriendRequest(userId: userId, friendCode: friendCode)
        let response: APIResponse<AddFriendResponse> = try await requestWithBody(
            endpoint: "friends",
            method: .POST,
            body: request
        )
        guard let data = response.data else {
            throw APIError.networkError(response.error ?? "Error agregando amigo")
        }
        return data
    }

    func removeFriend(friendId: String) async throws {
        let _: APIResponse<EmptyResponse> = try await request(
            endpoint: "friends/\(friendId)",
            method: .DELETE
        )
    }

    func getFriends() async throws -> [FriendProfile] {
        let response: APIResponse<[FriendProfile]> = try await request(
            endpoint: "friends",
            method: .GET
        )
        return response.data ?? []
    }

    // MARK: - Leaderboard

    func getLeaderboard() async throws -> LeaderboardResponse {
        let response: APIResponse<LeaderboardResponse> = try await request(
            endpoint: "friends/leaderboard",
            method: .GET
        )
        guard let data = response.data else {
            throw APIError.noData
        }
        return data
    }

    // MARK: - Training Completion & Streaks

    func completeWorkout(userId: String, date: String, planId: String?, dayName: String?) async throws {
        let request = CompleteWorkoutRequest(
            userId: userId,
            date: date,
            planId: planId,
            dayName: dayName
        )
        let _: APIResponse<EmptyResponse> = try await requestWithBody(
            endpoint: "training/completion",
            method: .POST,
            body: request
        )
    }

    func uncompleteWorkout(date: String) async throws {
        let _: APIResponse<EmptyResponse> = try await request(
            endpoint: "training/completion?date=\(date)",
            method: .DELETE
        )
    }

    func getCompletionStatus(date: String) async throws -> Bool {
        let response: APIResponse<Bool> = try await request(
            endpoint: "training/completion/status?date=\(date)",
            method: .GET
        )
        return response.data ?? false
    }

    func getMyStreak() async throws -> TrainingStreakResponse {
        let response: APIResponse<TrainingStreakResponse> = try await request(
            endpoint: "training/streak",
            method: .GET
        )
        guard let data = response.data else {
            throw APIError.noData
        }
        return data
    }
}
