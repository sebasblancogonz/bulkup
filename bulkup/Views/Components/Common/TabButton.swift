//
//  TabButton.swift
//  bulkup
//
//  Created by sebastian.blanco on 18/8/25.
//
import SwiftData
import SwiftUI

struct TabButton: View {
    let tab: MainAppView.AppTab
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.iconName)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(tab.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if isDisabled {
                    Text("Sin datos")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected ? tab.gradient : LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(isSelected ? .white : (isDisabled ? .secondary : .primary))
            .cornerRadius(12)
            .shadow(
                color: isSelected ? tab.primaryColor.opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
}
