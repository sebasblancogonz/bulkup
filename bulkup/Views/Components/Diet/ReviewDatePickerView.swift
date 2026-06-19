//
//  ReviewDatePickerView.swift
//  bulkup
//

import SwiftUI

struct ReviewDatePickerView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedDate: Date = Date().addingTimeInterval(28 * 24 * 3600) // 4 weeks default
    @State private var isSaving = false
    @State private var showDatePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(BulkUpColors.secondary)

                Text("Proxima Revision")
                    .font(BulkUpFont.cardTitle())
                    .fontWeight(.bold)
                    .foregroundColor(BulkUpColors.textPrimary)

                Spacer()

                if authManager.user?.nextReviewDate != nil {
                    Button {
                        showDatePicker.toggle()
                    } label: {
                        Text(showDatePicker ? "Listo" : "Cambiar")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.secondary)
                    }
                }
            }

            if let reviewDate = authManager.user?.nextReviewDate {
                if !showDatePicker {
                    HStack {
                        Text(reviewDate.formatted(date: .abbreviated, time: .omitted))
                            .font(BulkUpFont.sectionHeader())
                            .foregroundColor(BulkUpColors.textPrimary)

                        Spacer()

                        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: reviewDate).day ?? 0
                        Text("Faltan \(max(daysRemaining, 0)) dias")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.secondary)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(BulkUpColors.secondary.opacity(0.1))
                            .cornerRadius(CornerRadius.small)
                    }
                } else {
                    datePickerSection
                }
            } else {
                datePickerSection
            }
        }
        .cardStyle()
        .onAppear {
            if let existing = authManager.user?.nextReviewDate {
                selectedDate = existing
            }
        }
    }

    private var datePickerSection: some View {
        VStack(spacing: Spacing.md) {
            DatePicker(
                "Fecha de revision",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()

            Button {
                saveReviewDate()
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    Text(isSaving ? "Guardando..." : "Guardar Fecha")
                        .fontWeight(.medium)
                }
                .font(BulkUpFont.body())
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(BulkUpColors.secondary)
                .foregroundColor(.white)
                .cornerRadius(CornerRadius.small)
            }
            .disabled(isSaving)
        }
    }

    private func saveReviewDate() {
        guard authManager.user?.id != nil else { return }
        isSaving = true

        Task {
            let request = UpdateProfileRequest(nextReviewDate: selectedDate)
            do {
                _ = try await APIService.shared.updateProfile(request: request)
                authManager.user?.nextReviewDate = selectedDate
                showDatePicker = false
            } catch {
                // Handle error silently
            }
            isSaving = false
        }
    }
}
