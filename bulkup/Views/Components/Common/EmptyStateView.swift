//
//  EmptyStateView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//
import SwiftData
import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    // Optional primary button
    var actionTitle: String? = nil
    var actionIcon: String? = nil
    var action: (() -> Void)? = nil

    // Optional secondary button
    var secondaryActionTitle: String? = nil
    var secondaryActionIcon: String? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: color.opacity(0.2), radius: 20, x: 0, y: 10)
            }

            VStack(spacing: Spacing.lg) {
                Text(title)
                    .font(BulkUpFont.sectionHeader())
                    .foregroundColor(BulkUpColors.textPrimary)

                Text(subtitle)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.screenH)
            }

            // Buttons section
            if actionTitle != nil || secondaryActionTitle != nil {
                VStack(spacing: Spacing.md) {
                    // Primary button
                    if let actionTitle = actionTitle, let action = action {
                        Button(action: action) {
                            HStack(spacing: Spacing.md) {
                                if let actionIcon = actionIcon {
                                    Image(systemName: actionIcon)
                                        .font(BulkUpFont.sectionHeader())
                                }

                                Text(actionTitle)
                            }
                            .primaryButtonStyle(color: color)
                        }
                    }

                    // Secondary button
                    if let secondaryTitle = secondaryActionTitle, let secondaryAction = secondaryAction {
                        Button(action: secondaryAction) {
                            HStack(spacing: Spacing.sm) {
                                if let secondaryIcon = secondaryActionIcon {
                                    Image(systemName: secondaryIcon)
                                        .font(BulkUpFont.body())
                                }

                                Text(secondaryTitle)
                                    .fontWeight(.semibold)
                            }
                            .secondaryButtonStyle()
                        }
                    }
                }
                .padding(.horizontal, Spacing.xxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
