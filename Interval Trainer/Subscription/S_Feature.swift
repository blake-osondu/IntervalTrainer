import ComposableArchitecture
import StoreKit
import Foundation

@Reducer
struct SubscriptionFeature {
    @ObservableState
    struct State: Equatable {
        var isSubscribed = false
        var availableSubscriptions: [AppProduct] = []
        var isLoading = false
        var error: String?
        var currentImageIndex = 0
        var displayedImage: String {
            "onboarding\(currentImageIndex + 1)"
        }
    }
    
    enum Action {
        case didAppear
        case checkSubscriptionStatus
        case subscriptionStatusUpdated(Bool)
        case loadProducts
        case productsLoaded([AppProduct])
        case purchase(AppProduct)
        case purchaseCompleted
        case restorePurchases
        case setError(String?)
        case timerTicked
    }
    
    @Dependency(\.subscriptionClient) var subscriptionClient
    @Dependency(\.continuousClock) var clock
    
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .didAppear:
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(3)) {
                        await send(.timerTicked)
                    }
                }
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
                
            case .setError:
                state.error = "Sorry, there was an error with your transaction. Please try again."
                state.isLoading = false
                return .none
                
            case .timerTicked:
                state.currentImageIndex = (state.currentImageIndex + 1) % 9
                return .none
            }
        }
    }
}
