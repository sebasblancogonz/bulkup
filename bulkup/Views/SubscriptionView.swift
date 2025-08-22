//
//  SubscriptionView.swift
//  bulkup
//
//  Vista de planes de suscripción
//

import StoreKit
import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con gradiente
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.05),
                        Color.purple.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerView
                        
                        // Beneficios
                        benefitsSection
                        
                        // Planes
                        if storeManager.isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding()
                        } else {
                            plansSection
                        }
                        
                        // Footer
                        footerSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay(
                Group {
                    if isPurchasing {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .overlay(
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                    Text("Procesando...")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                }
                                .padding(32)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(16)
                            )
                    }
                }
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding()
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.2), .purple.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            Text("Desbloquea Todo el Potencial")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Accede a todas las funciones premium y lleva tu entrenamiento al siguiente nivel")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Todo lo que obtienes:")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                BenefitRow(
                    icon: "doc.badge.plus",
                    title: "Planes Ilimitados",
                    description: "Sube y gestiona todos los planes que necesites"
                )
                
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Análisis Avanzado",
                    description: "Seguimiento detallado de tu progreso"
                )
                
                BenefitRow(
                    icon: "icloud.and.arrow.up",
                    title: "Sincronización en la Nube",
                    description: "Accede a tus datos desde cualquier dispositivo"
                )
                
                BenefitRow(
                    icon: "bell.badge",
                    title: "Notificaciones Inteligentes",
                    description: "Recordatorios personalizados para tus entrenamientos"
                )
                
                BenefitRow(
                    icon: "person.2.fill",
                    title: "Soporte Prioritario",
                    description: "Atención personalizada y respuesta rápida"
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Plans Section
    private var plansSection: some View {
        VStack(spacing: 16) {
            Text("Elige tu plan:")
                .font(.headline)
            
            ForEach(storeManager.products.sorted(by: { $0.price < $1.price }), id: \.id) { product in
                SubscriptionPlanCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    isPopular: product.id.contains("yearly"),
                    onSelect: {
                        selectedProduct = product
                    }
                )
            }
            
            // Botón de compra
            if let selectedProduct = selectedProduct {
                Button(action: {
                    Task {
                        await purchaseProduct(selectedProduct)
                    }
                }) {
                    HStack {
                        Text("Suscribirse")
                        Text("•")
                        Text(storeManager.priceString(for: selectedProduct))
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 16) {
            // Restaurar compras
            Button(action: {
                Task {
                    await restorePurchases()
                }
            }) {
                Text("Restaurar Compras")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            // Términos y privacidad
            HStack(spacing: 16) {
                Link("Términos de Uso", destination: URL(string: "https://tuapp.com/terms")!)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Link("Política de Privacidad", destination: URL(string: "https://tuapp.com/privacy")!)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Información de suscripción
            Text("Las suscripciones se renuevan automáticamente a menos que se cancelen al menos 24 horas antes del final del período actual. Puedes gestionar y cancelar tus suscripciones en la configuración de tu cuenta de App Store.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Si ya tiene suscripción
            if storeManager.hasActiveSubscription {
                VStack(spacing: 8) {
                    Label("Suscripción Activa", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let expirationDate = storeManager.expirationDate {
                        Text("Expira: \(expirationDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Gestionar Suscripción") {
                        Task {
                            await storeManager.openSubscriptionManagement()
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Purchase Product
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        
        do {
            if (try await storeManager.purchase(product)) != nil {
                isPurchasing = false
                dismiss()
            } else {
                isPurchasing = false
            }
        } catch {
            isPurchasing = false
            errorMessage = "Error al procesar la compra: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    // MARK: - Restore Purchases
    private func restorePurchases() async {
        isPurchasing = true
        await storeManager.restorePurchases()
        isPurchasing = false
        
        if storeManager.hasActiveSubscription {
            dismiss()
        } else {
            errorMessage = "No se encontraron compras previas para restaurar."
            showingError = true
        }
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Subscription Plan Card
struct SubscriptionPlanCard: View {
    let product: Product
    let isSelected: Bool
    let isPopular: Bool
    let onSelect: () -> Void
    
    @StateObject private var storeManager = StoreKitManager.shared
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                if isPopular {
                    Text("MÁS POPULAR")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .orange.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(planTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(planDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(storeManager.priceString(for: product))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let savings = calculateSavings() {
                            Text(savings)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.purple : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? .purple.opacity(0.2) : .clear,
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var planTitle: String {
        if product.id.contains("monthly") {
            return "Mensual"
        } else if product.id.contains("yearly") {
            return "Anual"
        } else {
            return storeManager.periodString(for: product).capitalized
        }
    }
    
    private var planDescription: String {
        if product.id.contains("monthly") {
            return "Facturado mensualmente"
        } else if product.id.contains("yearly") {
            return "Facturado anualmente"
        } else {
            return "Facturado \(storeManager.periodString(for: product))"
        }
    }
    
    private func calculateSavings() -> String? {
        guard product.id.contains("yearly"),
              let monthlyProduct = storeManager.products.first(where: { $0.id.contains("monthly") }) else {
            return nil
        }
        
        let yearlyCost = NSDecimalNumber(decimal: product.price).doubleValue
        let monthlyCost = NSDecimalNumber(decimal: monthlyProduct.price).doubleValue
        let monthlyCostPerYear = monthlyCost * 12.0
        let savings = monthlyCostPerYear - yearlyCost
        
        guard savings > 0 else { return nil }
        
        let percentage = Int((savings / monthlyCostPerYear) * 100.0)
        return "Ahorra \(percentage)%"
    }
}
