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
    @ObservedObject private var storeManager = StoreKitManager.shared
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
                        BulkUpColors.accent.opacity(0.05),
                        BulkUpColors.accent.opacity(0.02),
                        BulkUpColors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xxl) {
                        // Header
                        headerView

                        // Beneficios
                        benefitsSection

                        // Planes
                        if storeManager.hasActiveSubscription {
                            activeSubscriptionSection
                        } else if storeManager.isLoading {
                            ProgressView()
                                .scaleEffect(1.2)
                                .padding()
                        } else if storeManager.products.isEmpty {
                            emptyProductsSection
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
                    .foregroundColor(BulkUpColors.accent)
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
                                VStack(spacing: Spacing.lg) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                    Text("Procesando...")
                                        .foregroundColor(.white)
                                        .font(BulkUpFont.cardTitle())
                                }
                                .padding(32)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(CornerRadius.large)
                            )
                    }
                }
            )
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [BulkUpColors.accent, BulkUpColors.accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding()
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [BulkUpColors.accent.opacity(0.2), BulkUpColors.accent.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Text("Desbloquea Todo el Potencial")
                .font(BulkUpFont.sectionHeader())
                .foregroundColor(BulkUpColors.textPrimary)

            Text("Accede a todas las funciones premium y lleva tu entrenamiento al siguiente nivel")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Todo lo que obtienes:")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)
                .padding(.horizontal)

            VStack(spacing: Spacing.md) {
                BenefitRow(
                    icon: "sparkles",
                    title: "Importacion con IA",
                    description: "Sube una foto o PDF y tu plan se digitaliza al instante"
                )

                BenefitRow(
                    icon: "doc.badge.plus",
                    title: "Planes Ilimitados",
                    description: "Crea y gestiona todos los planes que necesites"
                )

                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Dashboard de Progreso",
                    description: "Medidas corporales, composicion y tendencias"
                )

                BenefitRow(
                    icon: "trophy.fill",
                    title: "Records Personales",
                    description: "Registra y sigue tus PR en los ejercicios principales"
                )

                BenefitRow(
                    icon: "person.2.fill",
                    title: "Ranking y Amigos",
                    description: "Compite con tus amigos y comparte planes"
                )

                BenefitRow(
                    icon: "square.and.arrow.up",
                    title: "Compartir Planes",
                    description: "Importa y exporta planes con codigos unicos"
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Active Subscription Section
    private var activeSubscriptionSection: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [BulkUpColors.success, BulkUpColors.success.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("¡Ya eres Premium!")
                .font(BulkUpFont.sectionHeader())
                .foregroundColor(BulkUpColors.textPrimary)

            Text("Tienes acceso a todas las funciones premium.")
                .font(BulkUpFont.body())
                .foregroundColor(BulkUpColors.textSecondary)
                .multilineTextAlignment(.center)

            if let expirationDate = storeManager.expirationDate {
                Text("Tu suscripción se renueva el \(expirationDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            Button(action: {
                Task {
                    await storeManager.openSubscriptionManagement()
                }
            }) {
                Text("Gestionar Suscripción")
                    .font(BulkUpFont.body())
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(BulkUpColors.accent)
                    .cornerRadius(CornerRadius.medium)
            }
        }
        .padding(Spacing.xl)
        .background(BulkUpColors.success.opacity(0.08))
        .cornerRadius(CornerRadius.large)
    }

    // MARK: - Empty Products Section
    private var emptyProductsSection: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(BulkUpColors.warning)

            Text("No se pudieron cargar los planes")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)

            if let error = storeManager.errorMessage {
                Text(error)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task {
                    await storeManager.loadProducts()
                }
            }) {
                Label("Reintentar", systemImage: "arrow.clockwise")
                    .font(BulkUpFont.body())
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(BulkUpColors.accent)
                    .cornerRadius(CornerRadius.medium)
            }
        }
        .padding()
        .background(BulkUpColors.surfaceElevated)
        .cornerRadius(CornerRadius.large)
    }

    // MARK: - Plans Section
    private var plansSection: some View {
        VStack(spacing: Spacing.lg) {
            Text("Elige tu plan:")
                .font(BulkUpFont.cardTitle())
                .foregroundColor(BulkUpColors.textPrimary)

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
                }
                .primaryButtonStyle(color: BulkUpColors.accent)
            }
        }
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: Spacing.lg) {
            // Restaurar compras
            Button(action: {
                Task {
                    await restorePurchases()
                }
            }) {
                Text("Restaurar Compras")
                    .font(BulkUpFont.body())
                    .foregroundColor(BulkUpColors.accent)
            }

            // Términos y privacidad
            HStack(spacing: Spacing.lg) {
                Link("Terminos de Uso", destination: URL(string: "https://getbulkup.com/terms")!)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)

                Text("•")
                    .foregroundColor(BulkUpColors.textSecondary)

                Link("Politica de Privacidad", destination: URL(string: "https://getbulkup.com/privacy")!)
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
            }

            // Información de suscripción
            Text("Las suscripciones se renuevan automáticamente a menos que se cancelen al menos 24 horas antes del final del período actual. Puedes gestionar y cancelar tus suscripciones en la configuración de tu cuenta de App Store.")
                .font(BulkUpFont.caption())
                .foregroundColor(BulkUpColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

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
            errorMessage = String(localized: "Error al procesar la compra: \(error.localizedDescription)")
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
            errorMessage = String(localized: "No se encontraron compras previas para restaurar.")
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
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(BulkUpFont.sectionHeader())
                .foregroundColor(BulkUpColors.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(title))
                    .font(BulkUpFont.body())
                    .fontWeight(.semibold)
                    .foregroundColor(BulkUpColors.textPrimary)

                Text(LocalizedStringKey(description))
                    .font(BulkUpFont.caption())
                    .foregroundColor(BulkUpColors.textSecondary)
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

    @ObservedObject private var storeManager = StoreKitManager.shared

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Spacing.md) {
                if isPopular {
                    Text("MÁS POPULAR")
                        .font(BulkUpFont.caption())
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(BulkUpColors.accentGradient)
                        )
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(planTitle)
                            .font(BulkUpFont.cardTitle())
                            .foregroundColor(BulkUpColors.textPrimary)

                        Text(planDescription)
                            .font(BulkUpFont.caption())
                            .foregroundColor(BulkUpColors.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(storeManager.priceString(for: product))
                            .font(BulkUpFont.sectionHeader())
                            .foregroundColor(BulkUpColors.textPrimary)

                        if let savings = calculateSavings() {
                            Text(savings)
                                .font(BulkUpFont.caption())
                                .foregroundColor(BulkUpColors.success)
                        }
                    }
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(BulkUpColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .stroke(
                                isSelected ? BulkUpColors.accent : BulkUpColors.textTertiary.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? BulkUpColors.accent.opacity(0.2) : .clear,
                radius: 10,
                x: 0,
                y: 5
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var planTitle: LocalizedStringKey {
        if product.id.contains("monthly") {
            return "Mensual"
        } else if product.id.contains("yearly") {
            return "Anual"
        } else {
            return LocalizedStringKey(storeManager.periodString(for: product).capitalized)
        }
    }

    private var planDescription: LocalizedStringKey {
        if product.id.contains("monthly") {
            return "Facturado mensualmente"
        } else if product.id.contains("yearly") {
            return "Facturado anualmente"
        } else {
            return LocalizedStringKey("Facturado \(storeManager.periodString(for: product))")
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
        return String(localized: "Ahorra \(percentage)%")
    }
}
