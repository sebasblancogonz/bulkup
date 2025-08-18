//
//  ExerciseExplorerView.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import SwiftData
import SwiftUI

struct ExerciseExplorerView: View {
    var body: some View {
        VStack {
            Text("🔍 Exercise Explorer")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Aquí iría el explorador de ejercicios")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
