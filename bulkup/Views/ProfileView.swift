//
//  ProfileView.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import SwiftData
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Avatar grande
                VStack(spacing: 16) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(authManager.user?.name.prefix(2).uppercased() ?? "US")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 4) {
                        Text(authManager.user?.name ?? "Usuario")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(authManager.user?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Opciones
                VStack(spacing: 12) {
                    ProfileMenuItem(icon: "person.crop.circle", title: "Editar Perfil", action: {})
                    ProfileMenuItem(icon: "bell", title: "Notificaciones", action: {})
                    ProfileMenuItem(icon: "gear", title: "Configuración", action: {})
                }
                .padding()
                
                Spacer()
                
                // Cerrar sesión
                Button(action: {
                    authManager.logout()
                    dismiss()
                }) {
                    Text("Cerrar Sesión")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Perfil")
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
