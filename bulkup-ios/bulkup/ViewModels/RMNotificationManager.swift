//
//  RMNotificationManager.swift
//  bulkup
//
//  Created by sebastianblancogonz on 20/8/25.
//
import SwiftUI

@MainActor
class RMNotificationManager: ObservableObject {
    static let shared = RMNotificationManager()
    @Published var currentNotification: NotificationData?
    private var hideTask: Task<Void, Never>?

    func showNotification(_ type: NotificationData.NotificationType, message: String) {
        hideTask?.cancel()

        withAnimation {
            currentNotification = NotificationData(type: type, message: message)
        }

        hideTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation {
                currentNotification = nil
            }
        }
    }

    func hideNotification() {
        hideTask?.cancel()
        withAnimation {
            currentNotification = nil
        }
    }
}
