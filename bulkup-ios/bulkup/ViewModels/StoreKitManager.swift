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
    @Published var errorMessage: String?

    /// Convenience alias used by paywall gates throughout the app
    var isSubscribed: Bool { hasActiveSubscription }
    
    // MARK: - Product IDs
    // Deben coincidir EXACTAMENTE con App Store Connect.
    private let productIds = [
        "bulkupmonthly",
        "bulkupyearly",
    ]
    
    // MARK: - Environment Detection
    var isTestEnvironment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Update Listener Task
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        print("🏪 StoreKitManager initialized in \(isTestEnvironment ? "DEBUG" : "RELEASE") mode")
        
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products with Enhanced Debug
    func loadProducts() async {
        print("🔄 Loading products...")
        
        do {
            isLoading = true
            errorMessage = nil
            
            // Verificar que estamos en un entorno compatible
            print("📱 Device supports StoreKit: \(AppStore.canMakePayments)")
            print("🆔 Requesting products for IDs: \(productIds)")
            
            // Cargar productos
            let loadedProducts = try await Product.products(for: productIds)
            
            print("✅ Successfully loaded \(loadedProducts.count) products")
            
            for product in loadedProducts {
                print("🏷️ Product: \(product.id)")
                print("   - Display Name: \(product.displayName)")
                print("   - Description: \(product.description)")
                print("   - Price: \(product.displayPrice)")
                print("   - Type: \(product.type)")
                
                if let subscription = product.subscription {
                    print("   - Subscription Period: \(subscription.subscriptionPeriod.unit) x\(subscription.subscriptionPeriod.value)")
                }
            }
            
            // Verificar productos faltantes
            let foundIds = Set(loadedProducts.map { $0.id })
            let requestedIds = Set(productIds)
            let missingIds = requestedIds.subtracting(foundIds)
            
            if !missingIds.isEmpty {
                print("⚠️ Missing products: \(missingIds)")
                errorMessage = "Productos no encontrados en App Store Connect: \(missingIds.joined(separator: ", "))"
            }
            
            products = loadedProducts
            isLoading = false
            
        } catch {
            print("❌ Error loading products: \(error)")
            
            // Diagnosticar el error específico
            if let storeKitError = error as? StoreKitError {
                switch storeKitError {
                case .networkError(let underlyingError):
                    errorMessage = "Error de red: \(underlyingError.localizedDescription)"
                case .systemError(let underlyingError):
                    errorMessage = "Error del sistema: \(underlyingError.localizedDescription)"
                case .userCancelled:
                    errorMessage = "Operación cancelada por el usuario"
                case .unknown:
                    errorMessage = "Error desconocido de StoreKit"
                default:
                    errorMessage = "Error no identificado: \(error.localizedDescription)"
                }
            } else {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Purchase with Enhanced Error Handling
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        print("🛒 Attempting to purchase: \(product.id)")
        
        guard AppStore.canMakePayments else {
            print("❌ Device cannot make payments")
            throw StoreError.paymentsNotAllowed
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            print("✅ Purchase successful for: \(product.id)")
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction
            
        case .userCancelled:
            print("🚫 User cancelled purchase")
            return nil
            
        case .pending:
            print("⏳ Purchase pending approval")
            return nil
            
        @unknown default:
            print("❓ Unknown purchase result")
            return nil
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        print("🔄 Restoring purchases...")
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ Purchases restored successfully")
        } catch {
            print("❌ Error restoring purchases: \(error)")
            errorMessage = "Error al restaurar compras: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Update Subscription Status
    /// Reads the current entitlements. Deliberately independent of `products`:
    /// if the product list failed to load (offline, App Store hiccup) a paying
    /// user must still be recognised as subscribed.
    func updateSubscriptionStatus() async {
        #if DEBUG
        if DesignPreview.isActive { return }   // keep the seeded status
        #endif
        print("🔄 Updating subscription status...")

        var hasActive = false
        var latestExpiration: Date?
        var activeProductID: String?

        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                guard transaction.productType == .autoRenewable,
                      productIds.contains(transaction.productID),
                      transaction.revocationDate == nil else { continue }

                if let expiration = transaction.expirationDate {
                    // currentEntitlements already filters expired ones, but the
                    // grace period / clock skew make an explicit check cheap.
                    guard expiration > Date() else {
                        print("❌ Subscription expired: \(expiration)")
                        continue
                    }
                    if latestExpiration == nil || expiration > latestExpiration! {
                        latestExpiration = expiration
                    }
                }
                hasActive = true
                activeProductID = transaction.productID
                print("✅ Active entitlement: \(transaction.productID)")
            } catch {
                print("❌ Error checking transaction: \(error)")
            }
        }

        if hasActive, let id = activeProductID,
           let product = products.first(where: { $0.id == id }),
           let status = try? await product.subscription?.status.first {
            subscriptionStatus = status.state
        } else {
            subscriptionStatus = nil
        }

        expirationDate = hasActive ? latestExpiration : nil
        hasActiveSubscription = hasActive
        print("📊 Has active subscription: \(hasActive)")
    }

    // MARK: - Listen for Transactions
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            print("👂 Listening for transaction updates...")
            
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    print("🔄 Transaction update received: \(transaction.productID)")
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("❌ Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verify Transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            print("❌ Transaction verification failed")
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
                print("❌ Error opening subscription management: \(error)")
            }
        }
    }
    
    // MARK: - Utility Methods
    func priceString(for product: Product) -> String {
        product.displayPrice
    }
    
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
            return "período desconocido"
        }
    }

    /// True for a yearly subscription — robust to the product ID (uses the period).
    func isYearly(_ product: Product) -> Bool {
        product.subscription?.subscriptionPeriod.unit == .year
    }

    func isMonthly(_ product: Product) -> Bool {
        product.subscription?.subscriptionPeriod.unit == .month
    }

    /// Localized free-trial label if the product has an introductory free-trial offer.
    func trialDescription(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let p = offer.period
        let unit: String
        switch p.unit {
        case .day: unit = p.value == 1 ? NSLocalizedString("día", comment: "") : NSLocalizedString("días", comment: "")
        case .week: unit = p.value == 1 ? NSLocalizedString("semana", comment: "") : NSLocalizedString("semanas", comment: "")
        case .month: unit = p.value == 1 ? NSLocalizedString("mes", comment: "") : NSLocalizedString("meses", comment: "")
        case .year: unit = p.value == 1 ? NSLocalizedString("año", comment: "") : NSLocalizedString("años", comment: "")
        @unknown default: unit = ""
        }
        return String(format: NSLocalizedString("%@ %@ gratis", comment: ""), "\(p.value)", unit)
    }
    
    // MARK: - Debug Helper
    func printDebugInfo() {
        print("🐛 === StoreKit Debug Info ===")
        print("📱 Can Make Payments: \(AppStore.canMakePayments)")
        print("🏪 Products Loaded: \(products.count)")
        print("🆔 Product IDs: \(productIds)")
        print("💰 Has Active Subscription: \(hasActiveSubscription)")
        print("📅 Expiration Date: \(expirationDate?.description ?? "None")")
        print("❌ Error Message: \(errorMessage ?? "None")")
        print("🏗️ Environment: \(isTestEnvironment ? "DEBUG" : "RELEASE")")
    }
}

// MARK: - Enhanced Store Error
enum StoreError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    case paymentsNotAllowed
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Falló la verificación de la transacción"
        case .productNotFound:
            return "Producto no encontrado"
        case .paymentsNotAllowed:
            return "Los pagos no están permitidos en este dispositivo"
        }
    }
}
