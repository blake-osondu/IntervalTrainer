//
//  WorkoutSummary.swift
//  Interval Trainer Watch Watch App
//
//  Created by Blake Osonduagwueki on 9/27/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct WorkoutSummaryFeature {
    @ObservableState
    struct State: Equatable {
        var lastWorkoutDate: Date?
        var workoutsThisMonth: Int = 0
        var currentStreak: Int = 0
        var isLoading: Bool = false
    }
    
    enum Action {
        case loadSummary
        case summaryLoaded(lastWorkout: Date?, monthlyCount: Int, streak: Int)
    }
    
    @Dependency(\.workoutSummaryClient) var workoutSummaryClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadSummary:
                state.isLoading = true
                return .run { send in
                    let summary = await workoutSummaryClient.loadWorkoutSummary()
                    await send(.summaryLoaded(
                        lastWorkout: summary.lastWorkoutDate,
                        monthlyCount: summary.workoutsThisMonth,
                        streak: summary.currentStreak
                    ))
                }
                
            case let .summaryLoaded(lastWorkout, monthlyCount, streak):
                state.isLoading = false
                state.lastWorkoutDate = lastWorkout
                state.workoutsThisMonth = monthlyCount
                state.currentStreak = streak
                return .none
            }
        }
    }
}

// You'll need to implement this client
struct WorkoutSummaryClient {
    var loadWorkoutSummary: @Sendable () async -> (lastWorkoutDate: Date?, workoutsThisMonth: Int, currentStreak: Int)
}

extension WorkoutSummaryClient: DependencyKey {
    static let liveValue = Self(
        loadWorkoutSummary: {
            // Implement this to load workout summary from your data store
            return (Date(), 10, 5)
        }
    )
}

extension DependencyValues {
    var workoutSummaryClient: WorkoutSummaryClient {
        get { self[WorkoutSummaryClient.self] }
        set { self[WorkoutSummaryClient.self] = newValue }
    }
}

struct WorkoutSummaryView: View {
    let store: StoreOf<WorkoutSummaryFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List {
                if viewStore.isLoading {
                    ProgressView()
                } else {
                    if let lastWorkout = viewStore.lastWorkoutDate {
                        Text("Last Workout: \(lastWorkout.formatted(date: .abbreviated, time: .omitted))")
                    } else {
                        Text("No workouts yet")
                    }
                    Text("This Month: \(viewStore.workoutsThisMonth)")
                    Text("Current Streak: \(viewStore.currentStreak) days")
                }
            }
            .navigationTitle("Summary")
            .onAppear {
                viewStore.send(.loadSummary)
            }
        }
    }
}

#Preview {
    WorkoutSummaryView(
        store: Store(
            initialState: WorkoutSummaryFeature.State(
                lastWorkoutDate: Date(),
                workoutsThisMonth: 12,
                currentStreak: 3
            ),
            reducer: {
                WorkoutSummaryFeature()
            }
        )
    )
}