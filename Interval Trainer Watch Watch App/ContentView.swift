//
//  ContentView.swift
//  Interval Trainer Watch Watch App
//
//  Created by Blake Osonduagwueki on 9/27/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct WatchAppFeature {
    @ObservableState
    struct State: Equatable {
        var workoutPlans = WorkoutPlansFeature.State()
        var subscription = SubscriptionFeature.State()
    }
    
    enum Action {
        case workoutPlans(WorkoutPlansFeature.Action)
        case subscription(SubscriptionFeature.Action)
    }
    
    @Dependency(\.watchConnectivity) var watchConnectivity

    func listenForWorkoutUpdates() -> Effect<Action> {
        .run { send in
            for await message in watchConnectivity.receive() {
                if let workoutState = WorkoutState.fromDictionary(message) {
                    await send(.workoutPlans(.performWorkout(.presented(.receivedWorkoutState(workoutState)))))
                }
            }
        }
    }
    var body: some Reducer<State, Action> {
        Scope(state: \.workoutPlans, action: \.workoutPlans) {
            WorkoutPlansFeature()
        }
        Scope(state: \.subscription, action: \.subscription) {
            SubscriptionFeature()
        }
        .onChange(of: \.workoutPlans.performWorkout) { oldValue, newValue in
            Reduce { state, _ in
                if newValue != nil {
                    return .send(.workoutPlans(.performWorkout(.presented(.syncWorkoutState))))
                }
                return .none
            }
        }
    }
}

extension WorkoutPlan {
    static let placeholder = WorkoutPlan(id: UUID(), name: "Placeholder", phases: [])
}


struct ContentView: View {
    let store: StoreOf<WatchAppFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            if viewStore.subscription.isSubscribed {
                NavigationStack {
                    List {
                        NavigationLink {
                            Watch_WorkoutPlansView(store: store.scope(state: \.workoutPlans, action: \.workoutPlans))
                        } label: {
                            Text("Workout Plans")
                        }
                    }
                    .navigationTitle("Interval Trainer")
                }
            } else {
                Text("Subscribe to use this Feature")
            }
        }
    }
}

#Preview {
    ContentView(
        store: Store(
            initialState: WatchAppFeature.State(),
            reducer: { WatchAppFeature() }
        )
    )
}
