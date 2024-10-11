import SwiftUI
import ComposableArchitecture
import StoreKit

struct SubscriptionView: View {
    let store: StoreOf<SubscriptionFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                LinearGradient(stops: [.init(color: Color.black, location: 0), .init(color: Color.gray, location: 1.0)], startPoint: .bottom, endPoint: .top).ignoresSafeArea(edges: .all)
                VStack {
                    if viewStore.isSubscribed {
                        Text("You are subscribed!")
                            .font(.headline)
                    } else {
                        Text("Subscribe to access all features")
                            .font(.headline)
                        
                        ForEach(viewStore.availableSubscriptions) { product in
                            VStack {
                                Text(product.displayName)
                                Text(product.description)
                                Text(product.displayPrice)
                                Button("Subscribe") {
                                    viewStore.send(.purchase(product))
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        }
                        
                        Button("Restore Purchases") {
                            viewStore.send(.restorePurchases)
                        }
                    }
                    
                    if viewStore.isLoading {
                        ProgressView()
                    }
                    
                    if let error = viewStore.error {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .onAppear {
                viewStore.send(.checkSubscriptionStatus)
                viewStore.send(.loadProducts)
            }
        }
    }
}
