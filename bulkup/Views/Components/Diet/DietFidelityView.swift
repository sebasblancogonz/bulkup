//
//  DietFidelityView.swift
//  bulkup
//
//  Diet-fidelity card: 30-day % of how close intake was to the plan's calorie
//  target, with a skipped-day log + list. PRO-gated.
//

import SwiftUI

struct DietFidelityView: View {
    @ObservedObject private var manager = DietFidelityManager.shared
    @ObservedObject private var dietManager = DietManager.shared
    @ObservedObject private var store = StoreKitManager.shared
    @State private var showingLog = false
    @State private var showingSubscription = false

    var body: some View {
        Group {
            if store.isSubscribed {
                content
            } else {
                Button {
                    showingSubscription = true
                } label: {
                    Label("Fidelidad a la dieta (PRO)", systemImage: "chart.pie.fill")
                        .font(BulkUpFont.cardTitle())
                        .foregroundColor(BulkUpColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BulkUpColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
                }
                .sheet(isPresented: $showingSubscription) {
                    SubscriptionView()
                }
            }
        }
        .task {
            if store.isSubscribed {
                await manager.load()
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Fidelidad a la dieta")
                    .font(BulkUpFont.cardTitle())
                    .foregroundColor(BulkUpColors.textPrimary)
                Spacer()
                Button {
                    showingLog = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(BulkUpColors.accent)
                }
            }

            if let pct = manager.fidelityPercent(dietData: dietManager.dietData) {
                Text("\(Int(pct.rounded()))%")
                    .font(BulkUpFont.heroStat())
                    .foregroundColor(BulkUpColors.accent)
                Text("últimos 30 días")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            } else {
                Text("—")
                    .font(BulkUpFont.heroStat())
                    .foregroundColor(BulkUpColors.textSecondary)
                Text("Registra días o añade calorías al plan")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            if !manager.skippedDays.isEmpty {
                ForEach(manager.skippedDays) { day in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(day.date)
                                .font(BulkUpFont.body())
                                .foregroundColor(BulkUpColors.textPrimary)
                            Text(day.description)
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\(day.calories) kcal")
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                        Button {
                            Task { await manager.deleteSkippedDay(day) }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(BulkUpColors.error)
                        }
                    }
                }
            }
        }
        .padding()
        .background(BulkUpColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        .sheet(isPresented: $showingLog) {
            LogSkippedDayView()
        }
    }
}

private struct LogSkippedDayView: View {
    @ObservedObject private var manager = DietFidelityManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var description = ""
    @State private var saving = false

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Día", selection: $date, in: ...Date(), displayedComponents: .date)
                Section("¿Qué comiste?") {
                    TextField("Ej: pizza familiar y 2 cervezas", text: $description, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Día saltado")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Estimando…" : "Guardar") {
                        saving = true
                        Task {
                            let ok = await manager.logSkippedDay(date: date, description: description)
                            saving = false
                            if ok { dismiss() }
                        }
                    }
                    .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty || saving)
                }
            }
        }
    }
}
