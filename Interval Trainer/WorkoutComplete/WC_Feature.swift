//
//  CompletedWorkout.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/10/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct WorkoutCompleteFeature {
    @ObservableState
    struct State: Equatable {
        var workoutRating: Int = 0
        var totalElapsedTime: String
        var totalCaloriesBurned: Int
    }
    
    @CasePathable
    enum Action: Equatable {
        case selectedWorkoutRating(Int)
        case selectedDiscardWorkout
        case selectedSaveWorkout
    }
    
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .selectedWorkoutRating(let rating):
                state.workoutRating = rating
                return .none
            case .selectedDiscardWorkout, .selectedSaveWorkout:
                return .none
            }
        }
    }
}
