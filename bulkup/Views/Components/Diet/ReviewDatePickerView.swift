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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.purple)

                Text("Proxima Revision")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                if authManager.user?.nextReviewDate != nil {
                    Button {
                        showDatePicker.toggle()
                    } label: {
                        Text(showDatePicker ? "Listo" : "Cambiar")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }

            if let reviewDate = authManager.user?.nextReviewDate {
                if !showDatePicker {
                    HStack {
                        Text(reviewDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.title3)
                            .fontWeight(.bold)

                        Spacer()

                        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: reviewDate).day ?? 0
                        Text("Faltan \(max(daysRemaining, 0)) dias")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                    }
                } else {
                    datePickerSection
                }
            } else {
                datePickerSection
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            if let existing = authManager.user?.nextReviewDate {
                selectedDate = existing
            }
        }
    }

    private var datePickerSection: some View {
        VStack(spacing: 12) {
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
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isSaving)
        }
    }

    private func saveReviewDate() {
        guard let userId = authManager.user?.id else { return }
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
