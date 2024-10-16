//
//  PerformWorkout.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/8/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import HealthKit

@Reducer
struct PerformWorkoutFeature {
    @ObservableState
    struct State: Equatable {
        var workoutPlan: WorkoutPlan
        var currentIntervalIndex: Int = 0
        var timeRemaining: TimeInterval = 0
        var isRunning: Bool = false
        var totalElapsedTime: TimeInterval = 0
        var totalTimeRemaining: TimeInterval {
            workoutPlan.totalDuration - totalElapsedTime
        }
        @Presents var editWorkout: EditWorkoutFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var workoutComplete: WorkoutCompleteFeature.State?
        var musicPlayer: MusicPlayerFeature.State = .init()
        var isSyncedWithCompanionDevice: Bool = false
        var caloriesBurned: Double = 0
        var workoutStartTime: Date?
        
        #if os(watchOS)
            var workoutSession: HKWorkoutSession?
        #endif
        
        init(workoutPlan: WorkoutPlan) {
            self.workoutPlan = workoutPlan
            self.timeRemaining = currentInterval?.duration ?? 0
        }
        
        var currentInterval: Interval? {
            workoutPlan.intervals[safe: currentIntervalIndex]
        }
    }
    
    @CasePathable
    enum Action {
        case timerTick
        case toggleRunning
        case skipInterval
        case rewindInterval
        case stopWorkout
        case dismiss
        case editWorkoutTapped
        case editWorkout(PresentationAction<EditWorkoutFeature.Action>)
        case updateCurrentRoutine(WorkoutPlan)
        case alert(PresentationAction<Alert>)
        case workoutCompleted
        case workoutComplete(PresentationAction<WorkoutCompleteFeature.Action>)
        case musicPlayer(MusicPlayerFeature.Action)
        case syncWorkoutState
        case receivedWorkoutState(WorkoutState)
        case startWorkout
        case endWorkout
        case updateCalories(Double)
        case saveCompletedWorkout(CompletedWorkout)
        case completedWorkoutSaved(CompletedWorkout)
        case failedToSaveCompletedWorkout(Error)

        @CasePathable
        enum Alert: Equatable {
            case updateCurrentRoutine
            case createNewRoutine
        }
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date) var date
    @Dependency(\.watchConnectivity) var watchConnectivity
    @Dependency(\.healthKitClient) var healthKitClient
    @Dependency(\.cloudKitClient) var cloudKitClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .timerTick:
                guard state.isRunning else { return .none }
                state.timeRemaining -= 1
                state.totalElapsedTime += 1
                if state.timeRemaining <= 0 {
                    return .send(.skipInterval)
                }
                return .none
                
            case .toggleRunning:
                state.isRunning.toggle()
                if state.isRunning {
                    return .run { send in
                        for await _ in self.clock.timer(interval: .seconds(1)) {
                            await send(.timerTick)
                        }
                    }
                }
                return .none
                
            case .skipInterval:
                return advanceToNextInterval(&state).map { action in
                    switch action {
                    case  .stopWorkout:
                        return .workoutCompleted
                    default:
                        return action
                    }
                }
                
            case .rewindInterval:
                return rewindToPreviousInterval(&state)
                
            case .stopWorkout:
                state.isRunning = false
                state.currentIntervalIndex = 0
                state.timeRemaining = state.currentInterval?.duration ?? 0
                return .none
                
            case .dismiss:
                return .none
                
            case .editWorkoutTapped:
                state.isRunning = false
                state.editWorkout = EditWorkoutFeature.State(workoutPlan: state.workoutPlan)
                return .none
                
            case .editWorkout(.presented(.save)):
                state.alert = AlertState {
                    TextState("Update Workout")
                } actions: {
                    ButtonState(action: .updateCurrentRoutine) {
                        TextState("Update Current Routine")
                    }
                    ButtonState(action: .createNewRoutine) {
                        TextState("Create New Routine")
                    }
                } message: {
                    TextState("Would you like to update the current routine or create a new routine?")
                }
                return .none
                
            case .editWorkout(.presented(.cancel)):
                state.editWorkout = nil
                return .none
                
            case let .updateCurrentRoutine(updatedPlan):
                state.workoutPlan = updatedPlan
                state.currentIntervalIndex = 0
                state.timeRemaining = state.currentInterval?.duration ?? 0
                state.editWorkout = nil
                state.alert = nil
                return .none
                
            case .alert(.presented(.updateCurrentRoutine)):
                guard let updatedPlan = state.editWorkout?.workoutPlan else { return .none }
                return .send(.updateCurrentRoutine(updatedPlan))
                
            case .alert(.presented(.createNewRoutine)):
                guard let updatedPlan = state.editWorkout?.workoutPlan else { return .none }
                // Here we need to communicate with the parent feature to add a new workout plan
                // For now, we'll just update the current plan
                return .send(.updateCurrentRoutine(updatedPlan))
                
            case .alert(.dismiss):
                state.alert = nil
                return .none
                
            case .workoutCompleted:
                state.workoutComplete = WorkoutCompleteFeature.State(totalElapsedTime: formatTime(state.totalElapsedTime), totalCaloriesBurned: Int(state.caloriesBurned))
                state.isRunning = false
                state.totalElapsedTime = 0
                state.currentIntervalIndex = 0
                state.timeRemaining = state.currentInterval?.duration ?? 0
                return .none
                
            case .workoutComplete(.presented(.selectedSaveWorkout)):
                let completedWorkout = CompletedWorkout(
                    id: UUID(),
                    name: state.workoutPlan.name,
                    date: self.date.now,
                    duration: state.totalElapsedTime,
                    caloriesBurned: 0,
                    rating: state.workoutComplete?.workoutRating ?? 0
                )
                state.workoutComplete = nil
                
                return .send(.saveCompletedWorkout(completedWorkout))

            case let .saveCompletedWorkout(workout):
                return .run { send in
                    do {
                        try await cloudKitClient.saveCompletedWorkout(workout)
                        await send(.completedWorkoutSaved(workout))
                    } catch {
                        await send(.failedToSaveCompletedWorkout(error))
                    }
                }
                
            case .completedWorkoutSaved:
                return .none
                
            case .failedToSaveCompletedWorkout:
                // Handle errors (e.g., show an alert)
//                state.isLoading = false
                return .none
                
            case .workoutComplete(.presented(.selectedDiscardWorkout)):
                // Reset the workout state or navigate back to the workout plans
                state.workoutComplete = nil
                return .none
                
            case .workoutComplete:
                return .none
                
            case .editWorkout, .alert:
                return .none
            
            case .musicPlayer(_):
                return .none
            
            case .syncWorkoutState:
                let workoutState = WorkoutState(
                    isRunning: state.isRunning,
                    currentIntervalIndex: state.currentIntervalIndex,
                    timeRemaining: state.timeRemaining,
                    totalElapsedTime: state.totalElapsedTime
                )
                return .run { _ in
                    self.watchConnectivity.send(workoutState.asDictionary())
                }
                
            case let .receivedWorkoutState(workoutState):
                state.isRunning = workoutState.isRunning
                state.currentIntervalIndex = workoutState.currentIntervalIndex
                state.timeRemaining = workoutState.timeRemaining
                state.totalElapsedTime = workoutState.totalElapsedTime
                state.isSyncedWithCompanionDevice = true
                return .none
            
            case .startWorkout:
                state.workoutStartTime = Date()
                #if os(watchOS)
                    if let session = try? healthKitClient.startWorkout() {
                        state.workoutSession = session
                    }
                #endif
                return .none
                
            case .endWorkout:
                guard let startTime = state.workoutStartTime else { return .none }
                
                #if os(watchOS)
                    guard let session = state.workoutSession else { return .none }
                    return .run { send in
                        let calories = await healthKitClient.endWorkout(session)
                        await send(.updateCalories(calories))
                        
                    }
                #else
                    return .run { send in
                        let calories = await healthKitClient.getActiveEnergyBurned(startTime, Date())
                        await send(.updateCalories(calories))
                        
                    }
                #endif
            
            case let .updateCalories(calories):
                state.caloriesBurned = calories
                return .none
            }
        }
        .ifLet(\.$editWorkout, action: \.editWorkout) {
            EditWorkoutFeature()
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$workoutComplete, action: \.workoutComplete) {
            WorkoutCompleteFeature()
        }
        
        Scope(state: \.musicPlayer, action: \.musicPlayer) {
            MusicPlayerFeature()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func advanceToNextInterval(_ state: inout State) -> Effect<Action> {
        state.totalElapsedTime += state.timeRemaining

        if state.currentIntervalIndex < state.workoutPlan.intervals.count - 1 {
            state.currentIntervalIndex += 1
        } else if state.currentIntervalIndex == state.workoutPlan.intervals.count - 1 {
            return .send(.stopWorkout)
        }
        
        state.timeRemaining = state.currentInterval?.duration ?? 0
        return .none
    }
    
    private func rewindToPreviousInterval(_ state: inout State) -> Effect<Action> {
        state.totalElapsedTime = max(0, state.totalElapsedTime - state.timeRemaining)
        if state.currentIntervalIndex > 0 {
            state.currentIntervalIndex -= 1
        }
        
        state.timeRemaining = state.currentInterval?.duration ?? 0
        return .none
    }
}

public struct WorkoutState: Codable, Equatable {
    public var isRunning: Bool
    public var currentIntervalIndex: Int
    public var timeRemaining: TimeInterval
    public var totalElapsedTime: TimeInterval
    
    public func asDictionary() -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
    
    public static func fromDictionary(_ dict: [String: Any]) -> WorkoutState? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let workoutState = try? JSONDecoder().decode(WorkoutState.self, from: data) else {
            return nil
        }
        return workoutState
    }
}
