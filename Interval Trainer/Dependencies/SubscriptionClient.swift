import StoreKit
import OSLog
import Dependencies

struct SubscriptionClient {
    var loadProducts: @Sendable () async -> Void
    var purchase: @Sendable (Product) async throws -> Void
    var updatePurchasedSubscriptions: @Sendable () async -> Void
    var restorePurchases: @Sendable () async throws -> Void
    var subscriptions: @Sendable () async -> [Product]
    var isSubscribed: @Sendable () async -> Bool
    
}

extension DependencyValues {
    var subscriptionClient: SubscriptionClient {
        get { self[SubscriptionClient.self] }
        set { self[SubscriptionClient.self] = newValue }
    }
}

extension SubscriptionClient: DependencyKey {
    static let liveValue: SubscriptionClient = Self {
        await SubscriptionManager.shared.loadProducts()
    } purchase: { product in
        try await SubscriptionManager.shared.purchase(product)
    } updatePurchasedSubscriptions: {
        await SubscriptionManager.shared.updatePurchasedSubscriptions()
    } restorePurchases: {
        try await SubscriptionManager.shared.restorePurchases()
    } subscriptions: {
        await SubscriptionManager.shared.subscriptions
    } isSubscribed: {
        await SubscriptionManager.shared.isSubscribed
    }
}

extension SubscriptionClient: TestDependencyKey {
    static let testValue: SubscriptionClient = Self {
        
    } purchase: { _ in
        
    } updatePurchasedSubscriptions: {
        
    } restorePurchases: {
        
    } subscriptions: {
        []
    } isSubscribed: {
        true
    }
}

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var isSubscribed = false
    
    private let productIds = ["your.subscription.product.id"]
    private let logger = Logger(subsystem: "com.yourapp.subscriptionmanager", category: "StoreKit")
    
    private init() {
        Task {
            await loadProducts()
            await updatePurchasedSubscriptions()
        }
    }
    
    func loadProducts() async {
        do {
            subscriptions = try await Product.products(for: productIds)
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .verified(let transaction):
                await transaction.finish()
                await updatePurchasedSubscriptions()
            case .unverified:
                throw SubscriptionError.failedVerification
            }
        case .userCancelled:
            throw SubscriptionError.userCancelled
        case .pending:
            throw SubscriptionError.pending
        @unknown default:
            throw SubscriptionError.unknown
        }
    }
    
    func updatePurchasedSubscriptions() async {
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productType == .autoRenewable {
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                    }
                }
            case .unverified:
                continue
            }
        }
        
        isSubscribed = !purchasedSubscriptions.isEmpty
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedSubscriptions()
    }
}

enum SubscriptionError: Error {
    case failedVerification
    case userCancelled
    case pending
    case unknown
}
