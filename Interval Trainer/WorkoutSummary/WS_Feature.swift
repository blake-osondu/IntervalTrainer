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
        var completedWorkouts: [CompletedWorkout] = []
        var lastWorkoutDate: Date?
        var workoutsThisMonth: Int = 0
        var workoutsThisWeek: Int = 0
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
    @Dependency(\.calendarClient) var calendar

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadCompletedWorkouts:
                state.isLoading = true
               return .run { send in
                    let workouts = await cloudKitClient.fetchCompletedWorkouts()
                    await send(.completedWorkoutsLoaded(workouts))
               }
            case let .completedWorkoutsLoaded(workouts):
                state.isLoading = false
                state.completedWorkouts = workouts

                let lastWorkoutDate = workouts.first?.date
                // Calculate workouts this month
                let currentDate = Date()
                let thisMonth = calendar.monthOf(currentDate)
                let thisYear = calendar.yearOf(currentDate)
                let thisWeek = calendar.weekOf(currentDate)

                let workoutsThisMonth = workouts.filter {
                    let workoutMonth = calendar.monthOf($0.date)
                    let workoutYear = calendar.yearOf($0.date)
                    return workoutMonth == thisMonth && workoutYear == thisYear
                }

                let workoutsThisWeek = workouts.filter {
                    let workoutMonth = calendar.monthOf($0.date)
                    let workoutYear = calendar.yearOf($0.date)
                    let workoutWeek = calendar.weekOf($0.date)
                    return workoutMonth == thisMonth && workoutWeek == thisWeek && workoutYear == thisYear
                }

                let numberOfWorkoutsThisMonth = workoutsThisMonth.count
                let numberOfWorkoutsThisWeek = workoutsThisWeek.count

                let caloriesBurnedThisMonth = workoutsThisMonth.map { $0.caloriesBurned}.reduce(0, +)
                let caloriesBurnedThisWeek = workoutsThisWeek.map { $0.caloriesBurned}.reduce(0, +)

                 // Calculate current streak
                let currentStreak = calculateStreak(workouts: workouts)
                
                // Simulating async load
                let summary = State(
                    lastWorkoutDate: lastWorkoutDate, // Yesterday
                    workoutsThisMonth: numberOfWorkoutsThisMonth,
                    workoutsThisWeek: numberOfWorkoutsThisWeek,
                    currentStreak: currentStreak,
                    caloriesBurnedThisWeek: caloriesBurnedThisWeek,
                    caloriesBurnedThisMonth: caloriesBurnedThisMonth
                )
                state = summary
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
