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

struct WorkoutCompleteView: View {
    let store: StoreOf<WorkoutCompleteFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 20) {
                Text("Workout Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("How was your workout?")
                    .font(.title2)
                
                HStack {
                    ForEach(1...5, id: \.self) { rating in
                        Button(action: {
                            viewStore.send(.selectedWorkoutRating(rating))
                        }) {
                            Image(systemName: rating <= (viewStore.workoutRating) ? "star.fill" : "star")
                                .font(.title)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Text("Total Time: \(viewStore.totalElapsedTime)")
                    .font(.title3)
                
                HStack(spacing: 20) {
                    Button("Save Workout") {
                        viewStore.send(.selectedSaveWorkout)
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Discard Workout") {
                        viewStore.send(.selectedDiscardWorkout)
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

#Preview("Workout Complete") {
    WorkoutCompleteView(
        store: Store(
            initialState: WorkoutCompleteFeature.State(totalElapsedTime: "5:00"),
            reducer: {
                WorkoutCompleteFeature()
            }
        )
    )
}
