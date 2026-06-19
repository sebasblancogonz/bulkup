//
//  ProfileMenuItem.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//
import SwiftData
import SwiftUI

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(BulkUpColors.accent.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(BulkUpColors.accent)
                }

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textTertiary)
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.lg)
            .background(BulkUpColors.surface)
            .cornerRadius(CornerRadius.large)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
