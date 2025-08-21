//
//  SubscriptionRequiredView.swift
//  bulkup
//
//  Created by sebastian.blanco on 21/8/25.
//
import SwiftUI

struct SubscriptionRequiredView: View {
    let onSubscribe: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .purple.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .purple.opacity(0.2), radius: 20, x: 0, y: 10)
            }
            
            VStack(spacing: 16) {
                Text("Función Premium")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Desbloquea el poder de subir y gestionar tus planes personalizados de entrenamiento y dieta")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 16) {
                // Beneficios
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "checkmark.circle.fill", text: "Sube planes ilimitados", color: .green)
                    FeatureRow(icon: "checkmark.circle.fill", text: "Seguimiento de progreso", color: .green)
                    FeatureRow(icon: "checkmark.circle.fill", text: "Análisis avanzados", color: .green)
                    FeatureRow(icon: "checkmark.circle.fill", text: "Sincronización en la nube", color: .green)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: onSubscribe) {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                        Text("Ver Planes de Suscripción")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 32)
                
                Text("Cancela en cualquier momento")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}
