//
//  MealCardView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import SwiftUI
import SwiftData

// MARK: - Expandable meal card — premium card-based design
struct MealCardView: View {
    let meal: Meal
    var trackingRecord: MealTrackingRecord?
    var isExpanded: Bool = false
    var onToggleExpand: (() -> Void)?
    var onToggleCompletion: (() -> Void)?
    var onNotesChanged: ((String) -> Void)?

    @State private var trackingNotes: String = ""
    @State private var showingRecipeChat = false

    private var isCompleted: Bool {
        trackingRecord?.completed ?? false
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed row — always visible
            collapsedRow

            // Expanded detail
            expandedDetail
                .frame(maxHeight: isExpanded ? nil : 0)
                .clipped()
                .opacity(isExpanded ? 1 : 0)
        }
        .background(BulkUpColors.surface)
        .cornerRadius(CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(BulkUpColors.border, lineWidth: 0.5)
        )
        // Completed: accent left border
        .overlay(alignment: .leading) {
            if isCompleted {
                UnevenRoundedRectangle(
                    topLeadingRadius: CornerRadius.large,
                    bottomLeadingRadius: CornerRadius.large,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(BulkUpColors.accent)
                .frame(width: 3)
            }
        }
        .clipped()
        .opacity(isCompleted ? 0.85 : 1.0)
        .padding(.horizontal, Spacing.screenH)
        .sheet(isPresented: $showingRecipeChat) {
            RecipeChatView(
                mealType: meal.type,
                ingredients: Array(Set(meal.options.flatMap { $0.ingredients })).sorted()
            )
        }
    }

    // MARK: - Collapsed Row

    private var collapsedRow: some View {
        HStack(spacing: Spacing.md) {
            // Completion indicator
            if trackingRecord != nil {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onToggleCompletion?()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(
                                isCompleted ? BulkUpColors.accent : BulkUpColors.muscleDefault,
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)

                        if isCompleted {
                            Circle()
                                .fill(BulkUpColors.accent)
                                .frame(width: 28, height: 28)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(BulkUpColors.onAccent)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
                }
                .buttonStyle(.plain)
            }

            // Meal info
            Button(action: { onToggleExpand?() }) {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.type.capitalized.replacingOccurrences(of: "_", with: " "))
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)
                            .opacity(isCompleted ? 0.5 : 1.0)

                        if !meal.time.isEmpty {
                            Text(meal.time)
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                                .fontDesign(.monospaced)
                        }
                    }

                    Spacer()

                    if isCompleted {
                        PillBadge(text: "Completado", color: BulkUpColors.accent, icon: "checkmark")
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BulkUpColors.textTertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
    }

    // MARK: - Expanded Detail

    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Divider()
                .background(BulkUpColors.border)

            // Meal notes (plan notes)
            if let notes = meal.notes, !notes.isEmpty {
                Text(notes)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            // Meal options
            ForEach(meal.options.indices, id: \.self) { index in
                MealOptionView(option: meal.options[index], mealType: meal.type)
            }

            // Conditional meals
            if let conditions = meal.conditions {
                MealConditionsView(conditions: conditions, mealType: meal.type)
            }

            // Recipe chat button
            Button {
                showingRecipeChat = true
            } label: {
                Label("Receta con IA", systemImage: "sparkles")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.accent)
            }
            .buttonStyle(.plain)

            // Tracking notes (when completed)
            if let record = trackingRecord, record.completed {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "note.text")
                        .foregroundColor(BulkUpColors.textTertiary)
                        .font(BulkUpFont.caption())

                    TextField("Notas (opcional)", text: $trackingNotes)
                        .font(BulkUpFont.caption())
                        .foregroundColor(BulkUpColors.textSecondary)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            onNotesChanged?(trackingNotes)
                        }
                }
                .onAppear {
                    trackingNotes = record.notes ?? ""
                }
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
}
