//
//  Home.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct Home {
    @ObservableState
    struct State: Equatable {
        var workoutSummary = WorkoutSummaryFeature.State()
        var completedWorkouts = CompletedWorkoutsFeature.State()
        var workoutPlans = WorkoutPlansFeature.State()
    }
    
    enum Action {
        case workoutSummary(WorkoutSummaryFeature.Action)
        case completedWorkouts(CompletedWorkoutsFeature.Action)
        case workoutPlans(WorkoutPlansFeature.Action)
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.workoutSummary, action: \.workoutSummary) {
            WorkoutSummaryFeature()
        }
        Scope(state: \.completedWorkouts, action: \.completedWorkouts) {
            CompletedWorkoutsFeature()
        }
        Scope(state: \.workoutPlans, action: \.workoutPlans) {
            WorkoutPlansFeature()
        }
    }
}
