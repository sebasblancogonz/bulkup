//
//  NotificationView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 18/8/25.
//
import SwiftData
import SwiftUI

struct NotificationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("🔔 Notificaciones")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("No hay notificaciones nuevas")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
