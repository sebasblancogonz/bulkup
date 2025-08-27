//
//  StoreKitManager.swift
//  bulkup
//
//  Gestor de suscripciones con StoreKit 2
//

import StoreKit
import SwiftUI

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var subscriptionStatus: Product.SubscriptionInfo.RenewalState?
    @Published var isLoading = false
    @Published var hasActiveSubscription = false
    @Published var expirationDate: Date?
    
    // MARK: - Product IDs
    // Estos deben coincidir con los configurados en App Store Connect
    private let productIds = [
        "bulkuppro"
    ]
    
    // MARK: - Update Listener Task
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    func loadProducts() async {
        do {
            isLoading = true
            products = try await Product.products(for: productIds)
            isLoading = false
        } catch {
            print("Error loading products: \(error)")
            isLoading = false
        }
    }
    
    // MARK: - Purchase Subscription
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction
            
        case .userCancelled:
            return nil
            
        case .pending:
            return nil
            
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("Error restoring purchases: \(error)")
        }
    }
    
    // MARK: - Update Subscription Status
    @MainActor
    func updateSubscriptionStatus() async {
        var hasActive = false
        
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    if transaction.productType == .autoRenewable {
                        if let expirationDate = transaction.expirationDate,
                           expirationDate > Date() {
                            hasActive = true
                            self.expirationDate = expirationDate
                            
                            // Obtener el estado de la suscripción
                            if let status = try? await product.subscription?.status.first {
                                self.subscriptionStatus = status.state
                            }
                        }
                    }
                }
            } catch {
                print("Error checking transaction: \(error)")
            }
        }
        
        self.hasActiveSubscription = hasActive
        
        // Actualizar el AuthManager si existe
        // Nota: AuthManager debería ser accesible a través de EnvironmentObject o similar
        // No usar AuthManager.shared aquí
    }
    
    // MARK: - Listen for Transactions
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verify Transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Cancel Subscription
    func openSubscriptionManagement() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("Error opening subscription management: \(error)")
            }
        }
    }
    
    // MARK: - Get Price String
    func priceString(for product: Product) -> String {
        product.displayPrice
    }
    
    // MARK: - Get Subscription Period
    func periodString(for product: Product) -> String {
        guard let subscription = product.subscription else { return "" }
        
        let period = subscription.subscriptionPeriod
        switch period.unit {
        case .day:
            return period.value == 1 ? "diario" : "\(period.value) días"
        case .week:
            return period.value == 1 ? "semanal" : "\(period.value) semanas"
        case .month:
            return period.value == 1 ? "mensual" : "\(period.value) meses"
        case .year:
            return period.value == 1 ? "anual" : "\(period.value) años"
        @unknown default:
            return "periodo desconocido"
        }
    }
}

// MARK: - Store Error
enum StoreError: Error {
    case failedVerification
    case productNotFound
}
