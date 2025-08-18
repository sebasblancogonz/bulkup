//
//  RMTrackerView.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import SwiftData
import SwiftUI

struct RMTrackerView: View {
    var body: some View {
        VStack {
            Text("🏋️ RM Tracker")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Aquí iría el componente de seguimiento de récords máximos")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
