//
//  View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/29/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


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
                
                if viewStore.totalCaloriesBurned > 0 {
                    Text("Calories Burned: \(viewStore.totalCaloriesBurned)")
                        .font(.title3)
                }
                
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
            initialState: WorkoutCompleteFeature.State(totalElapsedTime: "5:00", totalCaloriesBurned: 249),
            reducer: {
                WorkoutCompleteFeature()
            }
        )
    )
}

