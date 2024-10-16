//
//  AppFeature.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var home = Home.State()
        var subscription = SubscriptionFeature.State()

    }
    
    enum Action {
        case home(Home.Action)
        case subscription(SubscriptionFeature.Action)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
           return .none
        }
        Scope(state: \.home, action: \.home) {
            Home()
        }
        Scope(state: \.subscription, action: \.subscription) {
            SubscriptionFeature()
                .dependency(\.subscriptionClient, .testValue)
        }
        .onChange(of: \.home.workoutPlans.performWorkout) { oldValue, newValue in
            Reduce { state, _ in
                if newValue != nil {
                    return .send(.home(.workoutPlans(.performWorkout(.presented(.syncWorkoutState)))))
                }
                return .none
            }
        }
        ._printChanges()
    }
    
    @Dependency(\.watchConnectivity) var watchConnectivity
    
    func listenForWorkoutUpdates() -> Effect<Action> {
        .run { send in
            for await message in watchConnectivity.receive() {
                if let workoutState = WorkoutState.fromDictionary(message) {
                    await send(.home(.workoutPlans(.performWorkout(.presented(.receivedWorkoutState(workoutState))))))
                }
            }
        }
    }
}

struct ContentView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        WithViewStore(store, observe: {$0 }) { viewStore in
            if viewStore.subscription.isSubscribed {
                HomeView(store: store.scope(state: \.home, action: \.home))
            } else {
                SubscriptionView(store: store.scope(state: \.subscription, action: \.subscription))
            }
        }
    }
}
