//
//  WorkoutPlans.swift
//  Interval Trainer Watch Watch App
//
//  Created by Blake Osonduagwueki on 9/27/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct Watch_WorkoutPlansView: View {
    let store: StoreOf<WorkoutPlansFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List {
                ForEach(viewStore.workoutPlans) { plan in
                    Button(plan.name) {
                        viewStore.send(.selectWorkoutPlan(plan))
                    }
                }
            }
            .navigationTitle("Workout Plans")
            .onAppear {
                viewStore.send(.loadWorkoutPlans)
            }
        }
        .sheet(
            store: store.scope(
                state: \.$performWorkout,
                action: { .performWorkout($0) }
            )
        ) { performWorkoutStore in
            Watch_PerformWorkoutView(store: performWorkoutStore)
        }
    }
}

#Preview {
    Watch_WorkoutPlansView(
        store: Store(
            initialState: WorkoutPlansFeature.State(
                workoutPlans: [
                    WorkoutPlan(id: UUID(), name: "HIIT Workout", phases: []),
                    WorkoutPlan(id: UUID(), name: "Strength Training", phases: []),
                    WorkoutPlan(id: UUID(), name: "Cardio Blast", phases: [])
                ]
            ),
            reducer: {
                WorkoutPlansFeature()
//                    .dependency(\.workoutPlanClient, .testValue)
            }
        )
    )
}
