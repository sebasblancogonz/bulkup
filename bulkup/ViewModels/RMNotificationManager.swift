//
//  RMNotificationManager.swift
//  bulkup
//
//  Created by sebastian.blanco on 20/8/25.
//
import SwiftUI

class RMNotificationManager: ObservableObject {
    static let shared = RMNotificationManager()
    @Published var currentNotification: NotificationData?
    private var notificationTimer: Timer?
    
    func showNotification(_ type: NotificationData.NotificationType, message: String) {
        // Cancel previous timer if exists
        notificationTimer?.invalidate()
        
        // Show new notification
        withAnimation {
            currentNotification = NotificationData(type: type, message: message)
        }
        
        // Auto-hide after 5 seconds
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation {
                self.currentNotification = nil
            }
        }
    }
    
    func hideNotification() {
        notificationTimer?.invalidate()
        withAnimation {
            currentNotification = nil
        }
    }
}
