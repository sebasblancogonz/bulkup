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
                VStack(spacing: 16) {
                    Text("Elige una plantilla para empezar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

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
                .padding()
            }
            .navigationTitle("Plantillas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
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
                            .fill(template.color.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: template.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(template.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("\(template.daysPerWeek) días/semana")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Training days preview
                    ForEach(template.trainingDays, id: \.day) { day in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(day.day)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                if let workoutName = day.workoutName {
                                    Text("— \(workoutName)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            if let exercises = day.output {
                                ForEach(exercises, id: \.name) { exercise in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(template.color.opacity(0.4))
                                            .frame(width: 5, height: 5)

                                        Text(exercise.name)
                                            .font(.caption)
                                            .foregroundColor(.primary)

                                        Spacer()

                                        Text("\(exercise.sets)×\(exercise.reps)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 8)
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
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(template.color)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .transition(.opacity)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
