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
        @Presents var addWorkout: AddCompletedWorkoutFeature.State?

    }
    
    enum Action {
        case loadCompletedWorkouts
        case completedWorkoutsLoaded([CompletedWorkout])
        case failedToLoadCompletedWorkouts(Error)
        case addWorkoutButtonTapped
        case addWorkout(PresentationAction<AddCompletedWorkoutFeature.Action>)
        case saveCompletedWorkout(CompletedWorkout)
        case failedToSaveCompletedWorkout(Error)
        case completedWorkoutSaved(CompletedWorkout)


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
                
            case .addWorkoutButtonTapped:
                state.addWorkout = AddCompletedWorkoutFeature.State()
                return .none
            
            case .addWorkout(.presented(.saveWorkout)):
                guard let newWorkout = state.addWorkout.map({
                    CompletedWorkout(
                        name: $0.workoutName,
                        date: $0.date,
                        duration: $0.duration * 60, // Convert minutes to seconds
                        caloriesBurned: $0.caloriesBurned,
                        rating: $0.rating
                    )
                }) else { return .none }
                
                return .send(.saveCompletedWorkout(newWorkout))
            
            case let .saveCompletedWorkout(workout):
                return .run { send in
                    do {
                        try await cloudKitClient.saveCompletedWorkout(workout)
                        await send(.completedWorkoutSaved(workout))
                    } catch {
                        await send(.failedToSaveCompletedWorkout(error))
                    }
                }
            case .completedWorkoutSaved(let newWorkout):
                var workouts = state.weeklyWorkouts.map { $0.workouts }.flatMap{ $0 }
                workouts.append(newWorkout)
                state.weeklyWorkouts = organizeWorkoutsByWeek(workouts)
                return .none
                
            case .addWorkout:
                return .none
            case .failedToSaveCompletedWorkout(_):
                // Handle errors (e.g., show an alert)
                return .none
            }
        }
        .ifLet(\.$addWorkout, action: \.addWorkout) {
            AddCompletedWorkoutFeature()
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

