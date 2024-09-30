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
                    do {
                        let workouts = try await cloudKitClient.fetchCompletedWorkouts().get()
                        await send(.completedWorkoutsLoaded(workouts))
                        
                    } catch {
                        await send(.failedToLoadCompletedWorkouts(error))
                     }
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
    
    private func organizeWorkoutsByWeek(_ workouts: [CompletedWorkout]) -> [WeeklyWorkout] {
        let calendar = Calendar.current
        let groupedWorkouts = Dictionary(grouping: workouts) { workout in
            calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.date))!
        }
        
        return groupedWorkouts.map { weekStart, workouts in
            WeeklyWorkout(weekStart: weekStart, workouts: workouts.sorted(by: { $0.date > $1.date }))
        }.sorted(by: { $0.weekStart > $1.weekStart })
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

