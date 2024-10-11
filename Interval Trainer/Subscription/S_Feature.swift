import ComposableArchitecture
import StoreKit

@Reducer
struct SubscriptionFeature {
    @ObservableState
    struct State: Equatable {
        var isSubscribed = false
        var availableSubscriptions: [Product] = []
        var isLoading = false
        var error: String?
    }
    
    enum Action {
        case checkSubscriptionStatus
        case subscriptionStatusUpdated(Bool)
        case loadProducts
        case productsLoaded([Product])
        case purchase(Product)
        case purchaseCompleted
        case restorePurchases
        case setError(String?)
    }
    
    @Dependency(\.subscriptionClient) var subscriptionClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .checkSubscriptionStatus:
                state.isLoading = true
                return .run { send in
                    await subscriptionClient.updatePurchasedSubscriptions()
                    await send(.subscriptionStatusUpdated(subscriptionClient.isSubscribed()))
                }
                
            case let .subscriptionStatusUpdated(isSubscribed):
                state.isSubscribed = isSubscribed
                state.isLoading = false
                return .none
                
            case .loadProducts:
                state.isLoading = true
                return .run { send in
                    await subscriptionClient.loadProducts()
                    await send(.productsLoaded(subscriptionClient.subscriptions()))
                }
                
            case let .productsLoaded(products):
                state.availableSubscriptions = products
                state.isLoading = false
                return .none
                
            case let .purchase(product):
                state.isLoading = true
                return .run { send in
                    do {
                        try await subscriptionClient.purchase(product)
                        await send(.purchaseCompleted)
                    } catch {
                        await send(.setError(error.localizedDescription))
                    }
                }
                
            case .purchaseCompleted:
                state.isLoading = false
                return .send(.checkSubscriptionStatus)
                
            case .restorePurchases:
                state.isLoading = true
                return .run { send in
                    do {
                        try await subscriptionClient.restorePurchases()
                        await send(.checkSubscriptionStatus)
                    } catch {
                        await send(.setError(error.localizedDescription))
                    }
                }
                
            case let .setError(error):
                state.error = error
                state.isLoading = false
                return .none
            }
        }
    }
}
