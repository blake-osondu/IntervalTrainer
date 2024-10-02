//
//  CompletedWorkouts.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import CloudKit

@Reducer
struct CompletedWorkoutsFeature {
    @ObservableState
    struct State: Equatable {
        var weeklyWorkouts: [WeeklyWorkout] = []
    }
    
    enum Action {
        case loadCompletedWorkouts
        case completedWorkoutsLoaded([CompletedWorkout])
        case failedToLoadCompletedWorkouts(Error)
        case addCompletedWorkoutTapped
    }
    
    @Dependency(\.cloudKitClient) var cloudKitClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadCompletedWorkouts:
                return .run { send in
                    let workouts = await cloudKitClient.fetchCompletedWorkouts()
                    await send(.completedWorkoutsLoaded(workouts))
                }
            
            case let .completedWorkoutsLoaded(workouts):
                state.weeklyWorkouts = organizeWorkoutsByWeek(workouts)
                return .none
            
            case .failedToLoadCompletedWorkouts:
                // Handle errors (e.g., show an alert)
                return .none
                
            case .addCompletedWorkoutTapped:
                // Handle tapping the add completed workout button
                return .none
            }
        }
    }
}

public struct CompletedWorkout: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let date: Date
    public let duration: TimeInterval
    public let caloriesBurned: Double
    public let rating: Int // Optional: Add a user rating for the workout
    
    public init(id: UUID = UUID(), name: String, date: Date, duration: TimeInterval, caloriesBurned: Double, rating: Int) {
        self.id = id
        self.name = name
        self.date = date
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.rating = rating
    }
}


public struct WeeklyWorkout: Equatable {
    public let weekStart: Date
    public let workouts: [CompletedWorkout]
}

