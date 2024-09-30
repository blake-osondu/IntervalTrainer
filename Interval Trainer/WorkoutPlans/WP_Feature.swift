//
//  WorkoutPlans.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct WorkoutPlansFeature {
    @ObservableState
    struct State: Equatable {
        var workoutPlans: [WorkoutPlan] = []
        var isExpanded = false
        var isLoading = false
        @Presents var workoutCreation: WorkoutCreationFeature.State?
        @Presents var performWorkout: PerformWorkoutFeature.State?
    }
    
    @CasePathable
    enum Action {
        case toggleExpanded
        case loadWorkoutPlans
        case failedToLoadWorkoutPlans(Error)
        case workoutPlansLoaded([WorkoutPlan])
        case createNewWorkoutPlan
        case workoutCreation(PresentationAction<WorkoutCreationFeature.Action>)
        case workoutPlanSelected(WorkoutPlan)
        case performWorkout(PresentationAction<PerformWorkoutFeature.Action>)
        case addNewWorkoutPlan(WorkoutPlan)
        case saveWorkoutPlan(WorkoutPlan)
        case workoutPlanSaved(WorkoutPlan)
        case failedToSaveWorkoutPlan(Error)

    }
    
    @Dependency(\.cloudKitClient) var cloudKitClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .toggleExpanded:
                state.isExpanded.toggle()
                return .none
            
            case .loadWorkoutPlans:
                state.isLoading = true
                return .run { send in
                    do {
                        let plans = try await cloudKitClient.fetchWorkoutPlans().get()
                        await send(.workoutPlansLoaded(plans))
                    } catch {
                        await send(.failedToLoadWorkoutPlans(error))
                    }
                }
                
            case let .workoutPlansLoaded(plans):
                state.isLoading = false
                state.workoutPlans = plans
                return .none
                
            case .createNewWorkoutPlan:
                var workoutCreation = WorkoutCreationFeature.State()
                workoutCreation.phases = .init(
                    arrayLiteral: .active(
                        ActivePhase(
                            id: UUID(),
                            intervals: [
                                .init(id: UUID(), name: "Warmup", type: .warmup, duration: 10.0),
                                .init(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 40.0),
                                .init(id: UUID(), name: "Low Intensity", type: .lowIntensity, duration: 20.0),
                                .init(id: UUID(), name: "Cooldown", type: .coolDown, duration: 30.0)
                            ])))
                state.workoutCreation = workoutCreation
                return .none
                
            case let .workoutPlanSelected(workoutPlan):
                state.performWorkout = PerformWorkoutFeature.State(workoutPlan: workoutPlan)
                return .none
                
            case .workoutCreation(.presented(.dismiss(let newPlan))):
                state.workoutCreation = nil
                return .send(.saveWorkoutPlan(newPlan))

            case .saveWorkoutPlan(let newPlan):
                return .run { send in
                    do {
                        try await cloudKitClient.saveWorkoutPlan(newPlan)
                        await send(.workoutPlanSaved(newPlan))
                    } catch {
                        await send(.failedToSaveWorkoutPlan(error))
                    }
                }
            case let .workoutPlanSaved(plan):
                if let index = state.workoutPlans.firstIndex(where: { $0.id == plan.id }) {
                    state.workoutPlans[index] = plan
                } else {
                    state.workoutPlans.append(plan)
                }
                return .none    
            case .workoutCreation(.presented(.cancel)):
                state.workoutCreation = nil
                return .none
                
            case .workoutCreation:
                return .none
                
            case .performWorkout(.presented(.dismiss)):
                state.performWorkout = nil
                return .none
                
            case let .addNewWorkoutPlan(newPlan):
                state.workoutPlans.append(newPlan)
                return .none
                
            case .performWorkout(.presented(.alert(.presented(.createNewRoutine)))):
                guard let updatedPlan = state.performWorkout?.editWorkout?.workoutPlan else { return .none }
                return .send(.addNewWorkoutPlan(updatedPlan))
                
            case .performWorkout:
                return .none

             case .failedToLoadWorkoutPlans, .failedToSaveWorkoutPlan:
                // Handle errors (e.g., show an alert)
                state.isLoading = false
                return .none
            
            }
        }
        .ifLet(\.$workoutCreation, action: \.workoutCreation) {
            WorkoutCreationFeature()
        }
        .ifLet(\.$performWorkout, action: \.performWorkout) {
           PerformWorkoutFeature()
        }
    }
}

extension WorkoutCreationFeature.State {
    func toWorkoutPlan() -> WorkoutPlan {
        WorkoutPlan(
            id: UUID(),
            name: self.workoutName,
            phases: Array(self.phases)
        )
    }
}

public struct WorkoutPlan: Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var phases: [WorkoutPhase]
    
    public var totalDuration: TimeInterval {
        phases.reduce(0) { $0 + $1.duration }
    }
}

public enum WorkoutPhase: Identifiable, Equatable, Codable {
    case active(ActivePhase)
    case rest(RestPhase)
    
    public var id: UUID {
        switch self {
        case .active(let phase): return phase.id
        case .rest(let phase): return phase.id
        }
    }
    
    public var duration: TimeInterval {
        switch self {
        case .active(let phase): return phase.totalDuration
        case .rest(let phase): return phase.duration
        }
    }
}

public struct ActivePhase: Identifiable, Equatable, Codable {
    public let id: UUID
    public var intervals: [Interval]
    
    public var totalDuration: TimeInterval {
        intervals.reduce(0) { $0 + $1.duration }
    }
}

public struct RestPhase: Identifiable, Equatable, Codable {
    public let id: UUID
    public var duration: TimeInterval
}

// Ensure this struct is defined in your project
public struct Interval: Identifiable, Equatable, Codable {
    public var id: UUID
    public var name: String
    public var type: IntervalType
    public var duration: TimeInterval
    
    public enum IntervalType: String, CaseIterable, Codable {
        case warmup = "Warm Up"
        case highIntensity = "High Intensity"
        case lowIntensity = "Low Intensity"
        case coolDown = "Cool Down"
    }
}
