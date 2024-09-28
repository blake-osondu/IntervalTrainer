//
//  WorkoutPlans.swift
//  Interval Trainer Watch Watch App
//
//  Created by Blake Osonduagwueki on 9/27/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct WorkoutPlansFeature {
    @ObservableState
    struct State: Equatable {
        var workoutPlans: [WorkoutPlan] = []
        @Presents var performWorkout: PerformWorkoutFeature.State?
    }
    
    enum Action {
        case loadWorkoutPlans
        case workoutPlansLoaded([WorkoutPlan])
        case selectWorkoutPlan(WorkoutPlan)
        case performWorkout(PresentationAction<PerformWorkoutFeature.Action>)
    }
    
    @Dependency(\.workoutPlanClient) var workoutPlanClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadWorkoutPlans:
                return .run { send in
                    let plans = await workoutPlanClient.loadWorkoutPlans()
                    await send(.workoutPlansLoaded(plans))
                }
                
            case let .workoutPlansLoaded(plans):
                state.workoutPlans = plans
                return .none
                
            case let .selectWorkoutPlan(plan):
                state.performWorkout = PerformWorkoutFeature.State(workoutPlan: plan)
                return .none
                
            case .performWorkout(.presented( let action)):
                if case .dismiss = action {
                    state.performWorkout = nil
                }
                return .none
            case .performWorkout(.dismiss):
                return .none
            }
        }
        .ifLet(\.$performWorkout, action: \.performWorkout) {
            PerformWorkoutFeature()
        }
    }
}

// You'll need to implement this client
struct WorkoutPlanClient {
    var loadWorkoutPlans: @Sendable () async -> [WorkoutPlan]
}

extension WorkoutPlanClient: DependencyKey {
    static let liveValue = Self(
        loadWorkoutPlans: {
            // Implement this to load workout plans from your data store
            [
                WorkoutPlan(id: UUID(), name: "HIIT Cardio", phases: [
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300)
                    ])),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30)
                    ])),
                    .rest(RestPhase(id: UUID(), duration: 60)),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30)
                    ])),
                    .rest(RestPhase(id: UUID(), duration: 60)),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                    ]))
                ]),
                WorkoutPlan(id: UUID(), name: "Strength Training", phases: [
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300)
                    ])),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60)
                    ])),
                    .rest(RestPhase(id: UUID(), duration: 90)),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60)
                    ])),
                    .rest(RestPhase(id: UUID(), duration: 90)),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                    ]))
                ])
            ]
        }
    )
    
    static let testValue = Self(
        loadWorkoutPlans: {
            // Implement this to load workout plans from your data store
            [
                WorkoutPlan(id: UUID(), name: "HIIT Cardio", phases: [
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300)
                    ])),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30)
                    ])),
                    .rest(RestPhase(id: UUID(), duration: 60)),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30)
                    ])),
                    .rest(RestPhase(id: UUID(), duration: 60)),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                    ]))
                ]),
                WorkoutPlan(id: UUID(), name: "Strength Training", phases: [
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300)
                    ])),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60)
                    ])),
                    .rest(RestPhase(id: UUID(), duration: 90)),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60)
                    ])),
                    .rest(RestPhase(id: UUID(), duration: 90)),
                    .active(ActivePhase(id: UUID(), intervals: [
                        Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                    ]))
                ])
            ]
        }
    )
}

extension DependencyValues {
    var workoutPlanClient: WorkoutPlanClient {
        get { self[WorkoutPlanClient.self] }
        set { self[WorkoutPlanClient.self] = newValue }
    }
}

struct WorkoutPlansView: View {
    let store: StoreOf<WorkoutPlansFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List {
                ForEach(viewStore.workoutPlans) { plan in
                    Button(plan.name) {
                        viewStore.send(.selectWorkoutPlan(plan))
                    }
                }
            }
            .navigationTitle("Workout Plans")
            .onAppear {
                viewStore.send(.loadWorkoutPlans)
            }
        }
        .sheet(
            store: store.scope(
                state: \.$performWorkout,
                action: { .performWorkout($0) }
            )
        ) { performWorkoutStore in
            PerformWorkoutView(store: performWorkoutStore)
        }
    }
}

#Preview {
    WorkoutPlansView(
        store: Store(
            initialState: WorkoutPlansFeature.State(
                workoutPlans: [
                    WorkoutPlan(id: UUID(), name: "HIIT Workout", phases: []),
                    WorkoutPlan(id: UUID(), name: "Strength Training", phases: []),
                    WorkoutPlan(id: UUID(), name: "Cardio Blast", phases: [])
                ]
            ),
            reducer: {
                WorkoutPlansFeature()
                    .dependency(\.workoutPlanClient, .testValue)
            }
        )
    )
}
