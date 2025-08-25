//
//  SupplementsView.swift
//  bulkup
//
//  Created by sebastianblancogonz on 17/8/25.
//

import SwiftUI
import SwiftData

struct SupplementsView: View {
    let supplements: [Supplement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header con más espaciado
            HStack(spacing: 16) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "pills.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suplementos")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(supplements.count) suplemento\(supplements.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Badge más grande y visible
                Text("\(supplements.count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.purple))
            }
            
            // Grid de suplementos con más espaciado
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(supplements.indices, id: \.self) { index in
                    SupplementCardView(supplement: supplements[index])
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .purple.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Card individual de suplemento
struct SupplementCardView: View {
    let supplement: Supplement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header del suplemento - altura fija
            HStack(alignment: .center, spacing: 12) {
                // Círculo de fondo para el icono
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: getSupplementIcon(supplement.name))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.purple)
                    )
                
                Text(supplement.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer(minLength: 0)
            }
            .frame(height: 48) // Altura fija para el header
            
            Spacer().frame(height: 16)
            
            // Información del suplemento - altura fija
            VStack(alignment: .leading, spacing: 10) {
                SupplementInfoRow(
                    icon: "speedometer",
                    label: "Dosis",
                    value: supplement.dosage,
                    color: .blue
                )
                
                SupplementInfoRow(
                    icon: "clock",
                    label: "Momento",
                    value: supplement.timing,
                    color: .orange
                )
                
                SupplementInfoRow(
                    icon: "repeat",
                    label: "Frecuencia",
                    value: supplement.frequency,
                    color: .green
                )
            }
            .frame(height: 96) // Altura fija para la información (3 filas × 32px)
            
            Spacer().frame(height: 12)
            
            // Área de notas - SIEMPRE presente con altura fija
            VStack(alignment: .leading, spacing: 8) {
                // Separador siempre visible
                Divider()
                    .background(Color.purple.opacity(0.1))
                
                // Contenedor de notas con altura fija
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "note.text")
                        .font(.system(size: 12))
                        .foregroundColor(hasNotes ? .purple.opacity(0.7) : .clear)
                        .frame(width: 16)
                    
                    if hasNotes {
                        Text(supplement.notes!)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("") // Espaciador invisible
                            .font(.system(size: 12))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(height: 32) // Altura fija para las notas
            }
            .frame(height: 52) // Altura fija total del área de notas (separador + contenido)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 224) // ALTURA COMPLETAMENTE FIJA
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.15), lineWidth: 1.5)
                )
        )
    }
    
    private var hasNotes: Bool {
        guard let notes = supplement.notes else { return false }
        return !notes.isEmpty
    }
    
    private func getSupplementIcon(_ name: String) -> String {
        let nameLower = name.lowercased()
        
        if nameLower.contains("protein") || nameLower.contains("proteina") {
            return "trophy.fill"
        } else if nameLower.contains("vitamin") || nameLower.contains("vitamina") {
            return "sun.max.fill"
        } else if nameLower.contains("creatine") || nameLower.contains("creatina") {
            return "bolt.fill"
        } else if nameLower.contains("omega") || nameLower.contains("fish") || nameLower.contains("aceite") {
            return "drop.fill"
        } else if nameLower.contains("magnesium") || nameLower.contains("magnesio") ||
                  nameLower.contains("zinc") || nameLower.contains("iron") || nameLower.contains("hierro") {
            return "cube.fill"
        } else {
            return "pills.fill"
        }
    }
}

// MARK: - Fila de información del suplemento
struct SupplementInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            // Icono con fondo circular
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            Spacer(minLength: 0)
        }
        .frame(height: 32) // Altura fija para cada fila
    }
}
