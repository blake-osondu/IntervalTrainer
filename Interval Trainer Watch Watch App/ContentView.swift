//
//  ContentView.swift
//  Interval Trainer Watch Watch App
//
//  Created by Blake Osonduagwueki on 9/27/24.
//

import SwiftUI
import ComposableArchitecture
import Foundation
import ComposableArchitecture

import Foundation
import ComposableArchitecture

@Reducer
struct WatchAppFeature {
    @ObservableState
    struct State: Equatable {
        var workoutPlans = WorkoutPlansFeature.State()
        var workoutSummary = WorkoutSummaryFeature.State()
    }
    
    enum Action {
        case workoutPlans(WorkoutPlansFeature.Action)
        case workoutSummary(WorkoutSummaryFeature.Action)
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.workoutPlans, action: \.workoutPlans) {
            WorkoutPlansFeature()
        }
        Scope(state: \.workoutSummary, action: \.workoutSummary) {
            WorkoutSummaryFeature()
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
            NavigationStack {
                List {
                    NavigationLink {
                        WorkoutPlansView(store: store.scope(state: \.workoutPlans, action: \.workoutPlans))
                    } label: {
                        Text("Workout Plans")
                    }
                    
                    NavigationLink {
                        WorkoutSummaryView(store: store.scope(state: \.workoutSummary, action: \.workoutSummary))
                    } label: {
                        Text("Workout Summary")
                    }
                }
                .navigationTitle("Interval Trainer")
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
