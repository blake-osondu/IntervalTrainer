//
//  Watch_WorkoutComplete.swift
//  Interval Trainer Watch Watch App
//
//  Created by Blake Osonduagwueki on 10/1/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


struct Watch_WorkoutCompleteView: View {
    var store: StoreOf<WorkoutCompleteFeature>
    var body: some View {
        WithViewStore(store, observe: {$0}) { viewStore in
            List {
                Text("WorkoutComplete")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Total Time: \(viewStore.totalElapsedTime)")
                    .font(.title3)
                
//                if viewStore.totalCaloriesBurned > 0 {
                    Text("Calories Burned: \(viewStore.totalCaloriesBurned)")
                        .font(.title3)
//                }
                Text("How was your workout?")
                    .font(.title2)
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
    }
}
