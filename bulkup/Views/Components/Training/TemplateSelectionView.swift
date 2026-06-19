//
//  TemplateSelectionView.swift
//  bulkup
//

import SwiftUI

struct TemplateSelectionView: View {
    let onSelect: (WorkoutTemplate) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var expandedTemplateId: UUID?

    private let templates = WorkoutTemplates.all

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Text("Elige una plantilla para empezar")
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)

                    ForEach(templates) { template in
                        TemplateCard(
                            template: template,
                            isExpanded: expandedTemplateId == template.id,
                            onTap: {
                                withAnimation(.spring()) {
                                    if expandedTemplateId == template.id {
                                        expandedTemplateId = nil
                                    } else {
                                        expandedTemplateId = template.id
                                    }
                                }
                            },
                            onSelect: {
                                onSelect(template)
                                dismiss()
                            }
                        )
                    }
                }
                .padding(Spacing.lg)
            }
            .background(BulkUpColors.background)
            .navigationTitle("Plantillas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(BulkUpColors.training)
                }
            }
        }
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: WorkoutTemplate
    let isExpanded: Bool
    let onTap: () -> Void
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onTap) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(BulkUpColors.training.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: template.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(BulkUpColors.training)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(template.name)
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)

                        Text("\(template.daysPerWeek) días/semana")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                }
                .padding(Spacing.lg)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Divider()

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(template.description)
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textSecondary)

                    // Training days preview
                    ForEach(template.trainingDays, id: \.day) { day in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(day.day)
                                    .font(BulkUpFont.body())
                                    .fontWeight(.semibold)
                                    .foregroundColor(BulkUpColors.textPrimary)

                                if let workoutName = day.workoutName {
                                    Text("— \(workoutName)")
                                        .font(BulkUpFont.body())
                                        .foregroundColor(BulkUpColors.textSecondary)
                                }
                            }

                            if let exercises = day.output {
                                ForEach(exercises, id: \.name) { exercise in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(BulkUpColors.training.opacity(0.4))
                                            .frame(width: 5, height: 5)

                                        Text(exercise.name)
                                            .font(BulkUpFont.caption())
                                            .foregroundColor(BulkUpColors.textPrimary)

                                        Spacer()

                                        Text("\(exercise.sets)×\(exercise.reps)")
                                            .font(BulkUpFont.caption())
                                            .foregroundColor(BulkUpColors.textSecondary)
                                    }
                                    .padding(.leading, Spacing.sm)
                                }
                            }
                        }
                    }

                    // Select button
                    Button(action: onSelect) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Usar esta plantilla")
                        }
                        .primaryButtonStyle(color: BulkUpColors.training)
                    }
                }
                .padding(Spacing.lg)
                .transition(.opacity)
            }
        }
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.medium)
    }
}
