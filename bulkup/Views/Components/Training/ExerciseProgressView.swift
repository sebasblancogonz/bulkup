//
//  ExerciseProgressView.swift
//  bulkup
//

import SwiftUI
import Charts

struct ExerciseProgressView: View {
    let exerciseName: String
    let exerciseIndex: Int
    let planId: String
    let weightTracking: Bool

    @State private var points: [ExerciseWeekPoint] = []
    @State private var loading = true
    @State private var metric: Metric = .weight
    private let lime = Color(red: 0.518, green: 0.800, blue: 0.086)

    enum Metric: String, CaseIterable { case weight = "Peso", volume = "Volumen", rm = "1RM" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(exerciseName).font(.title2.bold())

                if loading {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                } else if !weightTracking {
                    empty("Este ejercicio no registra peso.")
                } else if points.isEmpty {
                    empty("Registra tu primer peso para ver tu progreso aquí.")
                } else {
                    header
                    Picker("Métrica", selection: $metric) {
                        ForEach(Metric.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    chart
                    prList
                }
            }.padding()
        }
        .navigationTitle("Progreso")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func empty(_ msg: String) -> some View {
        Text(msg).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.top, 30)
    }

    @ViewBuilder private var header: some View {
        let last = points.last!
        let first = points.first!
        let delta = last.topSet - first.topSet
        let pct = first.topSet > 0 ? delta / first.topSet * 100 : 0
        HStack(spacing: 20) {
            stat("Serie tope", "\(fmt(last.topSet)) kg")
            stat("Récord", "\(fmt(points.map(\.topSet).max() ?? 0)) kg")
            stat("Desde el inicio", "\(delta >= 0 ? "+" : "")\(fmt(delta)) kg · \(Int(pct))%")
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).foregroundStyle(lime)
        }
    }

    private var chart: some View {
        Chart(points) { p in
            LineMark(x: .value("Semana", p.weekStart), y: .value(metric.rawValue, value(p)))
                .foregroundStyle(lime)
            PointMark(x: .value("Semana", p.weekStart), y: .value(metric.rawValue, value(p)))
                .foregroundStyle(isPR(p) ? lime : Color.secondary)
                .symbolSize(isPR(p) ? 110 : 50)
        }
        .frame(height: 240)
        .chartXAxisLabel("Semana")
    }

    private func value(_ p: ExerciseWeekPoint) -> Double {
        switch metric { case .weight: p.topSet; case .volume: p.volume; case .rm: p.est1RM }
    }

    private func isPR(_ p: ExerciseWeekPoint) -> Bool {
        metric == .rm ? p.isEst1RMPR : p.isWeightPR
    }

    @ViewBuilder private var prList: some View {
        let prs = points.filter(\.isWeightPR)
        if !prs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("PRs").font(.headline)
                ForEach(prs.reversed()) { p in
                    HStack {
                        Text("🏆 \(fmt(p.topSet)) kg × \(p.bestReps)")
                        Spacer()
                        Text(p.weekStart).foregroundStyle(.secondary).font(.caption)
                    }
                }
            }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        guard weightTracking, let userId = AuthManager.shared.user?.id else { return }
        let recs = (try? await APIService.shared.loadWeightHistory(userId: userId, planId: planId)) ?? []
        points = ExerciseProgress.points(from: recs, exerciseName: exerciseName, exerciseIndex: exerciseIndex)
    }

    private func fmt(_ w: Double) -> String {
        w == w.rounded() ? String(format: "%.0f", w) : String(format: "%.1f", w)
    }
}
