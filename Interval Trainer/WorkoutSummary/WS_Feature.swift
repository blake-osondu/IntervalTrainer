//
//  WorkoutSummary.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct WorkoutSummaryFeature {
    
    @ObservableState
    struct State: Equatable {
        var completedWorkouts: [WeeklyWorkout] = []
        var lastWorkoutDate: Date?
        var workoutsThisMonth: Int = 0
        var currentStreak: Int = 0
        var caloriesBurnedThisWeek: Double = 0
        var caloriesBurnedThisMonth: Double = 0
        var isLoading: Bool = false
    }
    
    enum Action {
        case loadCompletedWorkouts
        case completedWorkoutsLoaded([CompletedWorkout])
        case failedToLoadCompletedWorkouts(Error)
        case updateCalories(Double)
    }
    
    @Dependency(\.cloudKitClient) var cloudKitClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadCompletedWorkouts:
                state.isLoading = true
//                return .run { send in
//                    do {
//                        let workouts = try await cloudKitClient.fetchCompletedWorkouts().get()
//                        await send(.completedWorkoutsLoaded(workouts))
//                    } catch {
//                        await send(.failedToLoadCompletedWorkouts(error))
//                     }
//                }
                return .none
            case let .completedWorkoutsLoaded(workouts):
                state.isLoading = false
                // Simulating async load
                let summary = State(
                    lastWorkoutDate: Date().addingTimeInterval(-86400), // Yesterday
                    workoutsThisMonth: 15,
                    currentStreak: 5,
                    caloriesBurnedThisWeek: 1250,
                    caloriesBurnedThisMonth: 5430
                )
                
                return .none
                
            case .failedToLoadCompletedWorkouts:
                // Handle errors (e.g., show an alert)
                state.isLoading = false
                return .none
        
            case let .updateCalories(calories):
                state.caloriesBurnedThisWeek += calories
                state.caloriesBurnedThisMonth += calories
                return .none
            }
        }
    }
}
