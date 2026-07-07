//
//  TabButton.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//
import SwiftUI

struct TabButton: View {
    let tab: AppTab
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(BulkUpFont.sectionHeader())

                Text(LocalizedStringKey(tab.label))
                    .font(BulkUpFont.body())
                    .fontWeight(.semibold)

                if isDisabled {
                    Text("Sin datos")
                        .font(BulkUpFont.caption())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(BulkUpColors.surfaceElevated)
                        .cornerRadius(4)
                        .foregroundColor(BulkUpColors.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                isSelected
                    ? AnyShapeStyle(BulkUpColors.accent.opacity(0.15))
                    : AnyShapeStyle(BulkUpColors.surfaceElevated)
            )
            .foregroundColor(
                isSelected ? BulkUpColors.accent : (isDisabled ? BulkUpColors.textTertiary : BulkUpColors.textPrimary)
            )
            .cornerRadius(CornerRadius.medium)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.7),
                value: isSelected
            )
            .contentShape(Rectangle())
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
}
