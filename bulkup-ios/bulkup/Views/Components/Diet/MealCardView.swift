//
//  MealCardView.swift
//  bulkup
//
//  One meal as a row of the day's checklist: square sky check, name, the
//  first option as a hint, the time in tabular figures. The next meal to eat
//  sits on a raised fill; expanded, it shows its options and ingredients.
//

import SwiftUI
import SwiftData

struct MealCardView: View {
    let meal: Meal
    var trackingRecord: MealTrackingRecord?
    var isExpanded: Bool = false
    /// The first meal not yet ticked today: drawn on a raised row.
    var isNext: Bool = false
    var showsSeparator: Bool = true
    var onToggleExpand: (() -> Void)?
    var onToggleCompletion: (() -> Void)?
    var onNotesChanged: ((String) -> Void)?

    @State private var trackingNotes: String = ""
    @State private var showingRecipe = false

    private var isCompleted: Bool {
        trackingRecord?.completed ?? false
    }

    var body: some View {
        VStack(spacing: 0) {
            collapsedRow

            if isExpanded {
                expandedDetail
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(isNext ? BulkUpColors.surfaceElevated : Color.clear)
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle().fill(BulkUpColors.line).frame(height: 1).padding(.leading, Spacing.md)
            }
        }
        .sheet(isPresented: $showingRecipe) {
            RecipeView(
                mealType: meal.type,
                options: meal.options.enumerated().map { index, option in
                    RecipeOptionChoice(
                        id: "\(index)",
                        label: option.optionDescription.isEmpty ? "Opción \(index + 1)" : option.optionDescription,
                        ingredients: option.ingredients
                    )
                }
            )
        }
    }

    // MARK: - Collapsed Row

    private var collapsedRow: some View {
        HStack(spacing: Spacing.md) {
            // Square sky check (two-greens rule: sky means done)
            if trackingRecord != nil {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onToggleCompletion?()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(isCompleted ? BulkUpColors.complete : BulkUpColors.textTertiary.opacity(0.6), lineWidth: 1.5)
                            .frame(width: 26, height: 26)

                        if isCompleted {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(BulkUpColors.complete)
                                .frame(width: 26, height: 26)
                            Image(systemName: "checkmark")
                                .font(.system(.caption2, weight: .bold))
                                .foregroundColor(Color.onFill(BulkUpColors.complete))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
                }
                .buttonStyle(.plain)
                .frame(width: 26)
                .accessibilityLabel(isCompleted ? "Comida registrada" : "Marcar comida")
            }

            // Name, hint, time
            Button(action: { onToggleExpand?() }) {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(MealTypeLabel.localized(meal.type))
                            .font(.system(.headline, weight: .semibold))
                            .foregroundColor(isCompleted ? BulkUpColors.textSecondary : BulkUpColors.textPrimary)
                            .strikethrough(isCompleted, color: BulkUpColors.textSecondary)

                        if let first = meal.options.first?.optionDescription, !first.isEmpty, !isExpanded {
                            Text(first)
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: Spacing.sm)

                    if !meal.time.isEmpty {
                        Text(meal.time)
                            .font(BulkUpFont.numeric(.footnote, weight: .medium))
                            .foregroundColor(BulkUpColors.textSecondary)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(BulkUpColors.textTertiary)
                        .frame(width: 24, height: 24)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 12)
    }

    // MARK: - Expanded Detail

    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let notes = meal.notes, !notes.isEmpty {
                Text(notes)
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            ForEach(meal.options.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if meal.options.count > 1 {
                        Text("Opción \(index + 1)")
                            .font(.system(.caption, weight: .semibold))
                            .foregroundColor(BulkUpColors.textTertiary)
                    }
                    MealOptionView(option: meal.options[index], mealType: meal.type)
                }
            }

            if let conditions = meal.conditions {
                MealConditionsView(conditions: conditions, mealType: meal.type)
            }

            Button {
                showingRecipe = true
            } label: {
                Label("Receta con IA", systemImage: "sparkles")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundColor(BulkUpColors.accentText)
                    .frame(minHeight: 32)
            }
            .buttonStyle(.plain)

            if let record = trackingRecord, record.completed {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "note.text")
                        .font(.system(.footnote))
                        .foregroundColor(BulkUpColors.textTertiary)
                    TextField("Notas (opcional)", text: $trackingNotes)
                        .font(BulkUpFont.body())
                        .foregroundColor(BulkUpColors.textPrimary)
                        .onSubmit { onNotesChanged?(trackingNotes) }
                }
                .padding(.horizontal, Spacing.sm + 2)
                .frame(minHeight: 40)
                .background(isNext ? BulkUpColors.surface : BulkUpColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous))
                .onAppear { trackingNotes = record.notes ?? "" }
            }
        }
        .padding(.leading, trackingRecord != nil ? Spacing.md + 26 + Spacing.md : Spacing.md)
        .padding(.trailing, Spacing.md)
        .padding(.bottom, Spacing.md)
    }
}
