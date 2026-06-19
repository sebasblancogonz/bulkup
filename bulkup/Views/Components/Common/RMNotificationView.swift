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
            HStack(spacing: Spacing.sm) {
                Image(systemName: notification.type == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(notification.type == .success ? BulkUpColors.success : BulkUpColors.error)
                    .font(.system(size: 20))

                Text(notification.message)
                    .foregroundColor(BulkUpColors.textPrimary)
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .fill(BulkUpColors.surface)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(
                        notification.type == .success ? BulkUpColors.success.opacity(0.3) : BulkUpColors.error.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: notification.message)
        }
    }
}
