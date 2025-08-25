//
//  RMNotificationView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 20/8/25.
//
import SwiftUI

// MARK: - Models
struct NotificationData {
    let type: NotificationType
    let message: String
    
    enum NotificationType {
        case success
        case error
    }
}

struct RMNotificationView: View {
    let notification: NotificationData?
    
    var body: some View {
        if let notification = notification {
            HStack(spacing: 8) {
                Image(systemName: notification.type == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                
                Text(notification.message)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(notification.type == .success ? Color.green : Color.red)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: notification.message)
        }
    }
}
