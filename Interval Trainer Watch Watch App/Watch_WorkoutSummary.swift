//
//  WorkoutSummary.swift
//  Interval Trainer Watch Watch App
//
//  Created by Blake Osonduagwueki on 9/27/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct Watch_WorkoutSummaryView: View {
    let store: StoreOf<WorkoutSummaryFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List {
                if viewStore.isLoading {
                    ProgressView()
                } else {
                    if let lastWorkout = viewStore.lastWorkoutDate {
                        Text("Last Workout: \(lastWorkout.formatted(date: .abbreviated, time: .omitted))")
                    } else {
                        Text("No workouts yet")
                    }
                    Text("This Month: \(viewStore.workoutsThisMonth)")
                    Text("Current Streak: \(viewStore.currentStreak) days")
                    Text("Calories Burned: \(Int(viewStore.caloriesBurned))")

                }
            }
            .navigationTitle("Summary")
            .onAppear {
                viewStore.send(.loadSummary)
            }
        }
    }
}

#Preview {
    Watch_WorkoutSummaryView(
        store: Store(
            initialState: WorkoutSummaryFeature.State(
                lastWorkoutDate: Date(),
                workoutsThisMonth: 12,
                currentStreak: 3
            ),
            reducer: {
                WorkoutSummaryFeature()
            }
        )
    )
}
