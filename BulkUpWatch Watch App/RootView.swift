//
//  RootView.swift
//  BulkUpWatch Watch App
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var wc: WatchWCManager
    var body: some View {
        if let live = wc.live, !live.isFinished {
            ActiveWorkoutView(live: live)
        } else if let plan = wc.ctx?.todaysPlan, !plan.exercises.isEmpty {
            TodayView(plan: plan)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "iphone").font(.title2)
                Text("Open BulkUp on your iPhone").font(.footnote).multilineTextAlignment(.center)
            }.padding()
        }
    }
}
