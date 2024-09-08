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

struct CompletedWorkout: Identifiable, Equatable {
    let id: UUID
    let name: String
    let date: Date
    let duration: TimeInterval // Duration in seconds
}

struct HomeView: View {
    let store: StoreOf<Home>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        
                        Text("Workout Summary")
                            .font(.system(.title2, design: .rounded).bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        WorkoutSummaryView(
                            store: store.scope(
                                state: \.workoutSummary,
                                action: \.workoutSummary
                            )
                        )
                        
                        Text("Completed Workouts")
                            .font(.system(.title2, design: .rounded).bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        CompletedWorkoutsView(
                            store: store.scope(
                                state: \.completedWorkouts,
                                action: \.completedWorkouts
                            )
                        )
                        Spacer().frame(height: 50)
                    }
                    .padding(.top)
                }
                
                VStack {
                    Spacer()
                    WorkoutPlansOverlay(
                        store: store.scope(
                            state: \.workoutPlans,
                            action: \.workoutPlans
                        )
                    )
                }.edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}


#Preview {
    HomeView(store: .init(initialState: Home.State(), reducer: {
        Home()
    }))
}
