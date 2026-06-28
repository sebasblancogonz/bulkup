import SwiftUI

struct TodayView: View {
    @EnvironmentObject var wc: WatchWCManager
    let plan: TodaysPlan
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("TODAY")
                    .font(.caption2).fontWeight(.semibold).tracking(1.5)
                    .foregroundStyle(Color.lime)
                Text(plan.dayDisplay).font(.headline)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(plan.exercises, id: \.orderIndex) { ex in
                    HStack(alignment: .top, spacing: 8) {
                        Text(ex.name)
                            .font(.caption).lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                        Text("\(ex.sets)×\(ex.reps)")
                            .font(.caption2).fontWeight(.medium).monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6).padding(.horizontal, 9)
                    .background(Color.card, in: RoundedRectangle(cornerRadius: 9))
                }

                Button {
                    wc.send(.startWorkout(day: plan.dayDisplay))
                } label: {
                    Label("Start workout", systemImage: "play.fill")
                        .fontWeight(.semibold).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.lime).foregroundStyle(.black)
                .padding(.top, 6)
            }.padding()
        }
    }
}
