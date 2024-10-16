import StoreKit
import OSLog
import Dependencies

struct SubscriptionClient {
    var loadProducts: @Sendable () async -> Void
    var purchase: @Sendable (AppProduct) async throws -> Void
    var updatePurchasedSubscriptions: @Sendable () async -> Void
    var restorePurchases: @Sendable () async throws -> Void
    var subscriptions: @Sendable () async -> [AppProduct]
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
        await SubscriptionManager.shared.appSubscriptions
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
        [
            AppProduct(
                id: "com.yourapp.monthly",
                displayName: "Monthly Subscription",
                description: "Unlimited access for one month",
                price: 4.99,
                displayPrice: "$4.99"
            ),
            AppProduct(
                id: "com.yourapp.yearly",
                displayName: "Yearly Subscription",
                description: "Unlimited access for one year",
                price: 39.99,
                displayPrice: "$39.99"
            )
        ]
    } isSubscribed: {
        true
    }
}

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published private var subscriptions: [Product] = []
    @Published private(set) var appSubscriptions: [AppProduct] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var isSubscribed = false
    
    private let productIds = ["com.kinnectus.intervaltrainer.subscription.annual"]
    private let logger = Logger(subsystem: "com.kinnectus.intervaltrainer.subscriptionclient", category: "StoreKit")
    
    private init() {
        Task {
            await loadProducts()
            await updatePurchasedSubscriptions()
        }
    }
    
    func loadProducts() async {
        do {
            subscriptions = try await Product.products(for: productIds)
            appSubscriptions = subscriptions.map(mapProduct)
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
        }
    }
    
    func purchase(_ appProduct: AppProduct) async throws {
        guard let product = subscriptions.first(where: productForAppProduct(appProduct)) else { return }
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

let productForAppProduct: (AppProduct) -> (Product) -> Bool = { appProduct in
    return { product in
        product.id == appProduct.id
    }
}

let mapProduct: (Product) -> AppProduct = {
    .init(id: $0.id, displayName: $0.displayName, description: $0.description, price: $0.price, displayPrice: $0.displayPrice)
}

struct AppProduct: Identifiable, Equatable {
    let id: String
    let displayName: String
    let description: String
    let price: Decimal
    let displayPrice: String
}

enum SubscriptionError: Error {
    case failedVerification
    case userCancelled
    case pending
    case unknown
}
