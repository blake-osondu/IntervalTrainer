import SwiftUI
import ComposableArchitecture
import StoreKit

struct SubscriptionView: View {
    let store: StoreOf<SubscriptionFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 20) {
                
                    // Header
                    Text("Unlimited Access to All Features")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 10) {
                        Text("• Apple Watch Enabled")
                            .foregroundStyle(Color.black)
                        Text("• Interval Workout Templates")
                            .foregroundStyle(Color.black)
                        Text("• Sync across Devices")
                            .foregroundStyle(Color.black)
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                    
                    // Subscription Options
                    if viewStore.isSubscribed {
                        Text("You are subscribed!")
                            .font(.headline)
                            .foregroundColor(.green)
                    } else {
                        VStack(spacing: 15) {
                            ForEach(viewStore.availableSubscriptions) { product in
                                Button(action: {
                                    viewStore.send(.purchase(product))
                                }) {
                                    VStack {
                                        Text(product.displayName)
                                            .font(.headline)
                                        Text(product.description)
                                            .font(.subheadline)
                                        Text(product.displayPrice)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            viewStore.send(.restorePurchases)
                        }) {
                            Text("Restore Purchases")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    
                    if viewStore.isLoading {
                        ProgressView()
                    }
                    
                    if let error = viewStore.error {
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .background(
                // Onboarding Image
                Image(viewStore.displayedImage)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.3)
                    .animation(.easeInOut(duration: 1), value: viewStore.currentImageIndex))
            .onAppear {
                viewStore.send(.checkSubscriptionStatus)
                viewStore.send(.loadProducts)
                viewStore.send(.didAppear)
            }
        }
    }
}

#Preview {
    SubscriptionView(
        store: Store(
            initialState: SubscriptionFeature.State(
                isSubscribed: false,
                availableSubscriptions: [],
                isLoading: false,
                error: nil,
                currentImageIndex: 0
            )
        ) {
            SubscriptionFeature()
                .dependency(\.subscriptionClient, .testValue)
        }
    )
}
