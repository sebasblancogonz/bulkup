import SwiftUI

struct TodayView: View {
    @EnvironmentObject var wc: WatchWCManager
    let plan: TodaysPlan
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(plan.dayDisplay).font(.headline)
                ForEach(plan.exercises, id: \.orderIndex) { ex in
                    HStack {
                        Text(ex.name).font(.caption).lineLimit(1)
                        Spacer()
                        Text("\(ex.sets)×\(ex.reps)").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Button {
                    wc.send(.startWorkout(day: plan.dayDisplay))
                } label: {
                    Text("Start workout").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.518, green: 0.800, blue: 0.086)) // lime #84CC16
                .padding(.top, 6)
            }.padding()
        }
    }
}
