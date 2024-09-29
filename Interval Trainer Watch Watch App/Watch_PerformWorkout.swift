//
//  PerformWorkout.swift
//  Interval Trainer Watch Watch App
//
//  Created by Blake Osonduagwueki on 9/27/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import HealthKit

@Reducer
struct Watch_PerformWorkoutFeature {
    @ObservableState
    struct State: Equatable {
        var workoutPlan: WorkoutPlan
        var currentPhaseIndex: Int = 0
        var currentIntervalIndex: Int = 0
        var timeRemaining: TimeInterval = 0
        var isRunning: Bool = false
        var totalElapsedTime: TimeInterval = 0
        var isWorkoutComplete: Bool = false
        var isSyncedWithCompanionDevice: Bool = false

        init(workoutPlan: WorkoutPlan) {
            self.workoutPlan = workoutPlan
            self.timeRemaining = currentInterval?.duration ?? 0
        }
        
        var currentPhase: WorkoutPhase? {
            workoutPlan.phases[safe: currentPhaseIndex]
        }
        
        var currentInterval: Interval? {
            switch currentPhase {
            case .active(let activePhase):
                return activePhase.intervals[safe: currentIntervalIndex]
            case .rest(let restPhase):
                return Interval(id: UUID(), name: "Rest", type: .lowIntensity, duration: restPhase.duration)
            case .none:
                return nil
            }
        }
        var caloriesBurned: Double = 0
        var workoutSession: HKWorkoutSession?
    }
    
    enum Action {
        case timerTick
        case toggleRunning
        case skipInterval
        case stopWorkout
        case workoutCompleted
        case syncWorkoutState
        case receivedWorkoutState(WorkoutState)
        case dismiss
        case startWorkout
        case endWorkout
        case updateCalories(Double)
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.watchConnectivity) var watchConnectivity
    @Dependency(\.healthKitManager) var healthKitManager

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
                return advanceToNextInterval(&state)
                
            case .stopWorkout:
                state.isRunning = false
                state.isWorkoutComplete = true
                return .none
                
            case .workoutCompleted:
                state.isWorkoutComplete = true
                state.isRunning = false
                return .none
            case .syncWorkoutState:
                let workoutState = WorkoutState(
                    isRunning: state.isRunning,
                    currentPhaseIndex: state.currentPhaseIndex,
                    currentIntervalIndex: state.currentIntervalIndex,
                    timeRemaining: state.timeRemaining,
                    totalElapsedTime: state.totalElapsedTime
                )
                return .run { _ in
                    self.watchConnectivity.send(workoutState.asDictionary())
                }
                
            case let .receivedWorkoutState(workoutState):
                state.isRunning = workoutState.isRunning
                state.currentPhaseIndex = workoutState.currentPhaseIndex
                state.currentIntervalIndex = workoutState.currentIntervalIndex
                state.timeRemaining = workoutState.timeRemaining
                state.totalElapsedTime = workoutState.totalElapsedTime
                state.isSyncedWithCompanionDevice = true
                return .none    
            case .dismiss:
                // We don't need to do anything here, as the parent feature will handle the dismissal
                return .none
            case .startWorkout:
                state.workoutSession = healthKitManager.startWorkout()
                return .none
                
            case .endWorkout:
                guard let session = state.workoutSession else { return .none }
                return .run { send in
                    healthKitManager.endWorkout(session) { calories in
                        await send(.updateCalories(calories))
                    }
                }
                
            case let .updateCalories(calories):
                state.caloriesBurned = calories
                return .none
            }
        }
    }
    
    private func advanceToNextInterval(_ state: inout State) -> Effect<Action> {
        switch state.currentPhase {
        case .active(let activePhase):
            if state.currentIntervalIndex < activePhase.intervals.count - 1 {
                state.currentIntervalIndex += 1
            } else {
                state.currentPhaseIndex += 1
                state.currentIntervalIndex = 0
            }
        case .rest:
            state.currentPhaseIndex += 1
            state.currentIntervalIndex = 0
        case .none:
            return .send(.workoutCompleted)
        }
        
        if state.currentPhaseIndex >= state.workoutPlan.phases.count {
            return .send(.workoutCompleted)
        }
        
        state.timeRemaining = state.currentInterval?.duration ?? 0
        return .none
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct PerformWorkoutView: View {
    let store: StoreOf<Watch_PerformWorkoutFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            if viewStore.isWorkoutComplete {
                workoutCompleteView(viewStore: viewStore)
            } else {
                activeWorkoutView(viewStore: viewStore)
            }
        }
    }
    
    private func activeWorkoutView(viewStore: ViewStore<Watch_PerformWorkoutFeature.State, Watch_PerformWorkoutFeature.Action>) -> some View {
        VStack {
            Text(viewStore.workoutPlan.name)
                .font(.headline)
            
            Text(viewStore.currentInterval?.name ?? "")
                .font(.subheadline)
            
            Text(formatTime(viewStore.timeRemaining))
                .font(.system(size: 40, weight: .bold, design: .monospaced))
            
            Text("Calories Burned: \(Int(viewStore.caloriesBurned))")

            HStack {
                Button(action: { viewStore.send(.toggleRunning) }) {
                    Image(systemName: viewStore.isRunning ? "pause.fill" : "play.fill")
                }
                
                Button(action: { viewStore.send(.skipInterval) }) {
                    Image(systemName: "forward.fill")
                }
            }
            
            Button("Stop") {
                viewStore.send(.stopWorkout)
            }
            .foregroundColor(.red)
        }
        .onAppear {
            viewStore.send(.startWorkout)
        }
        .onDisappear {
            viewStore.send(.endWorkout)
        }
    }
    
    private func workoutCompleteView(viewStore: ViewStore<Watch_PerformWorkoutFeature.State, Watch_PerformWorkoutFeature.Action>) -> some View {
        VStack {
            Text("Workout Complete!")
                .font(.headline)
            
            Text("Total Time: \(formatTime(viewStore.totalElapsedTime))")
                .font(.subheadline)
            
            Button("Close") {
                viewStore.send(.dismiss)
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    PerformWorkoutView(
        store: Store(
            initialState: Watch_PerformWorkoutFeature.State(
                workoutPlan: WorkoutPlan(
                    id: UUID(),
                    name: "HIIT Workout",
                    phases: [
                        .active(ActivePhase(
                            id: UUID(),
                            intervals: [
                                Interval(id: UUID(), name: "Light Jog", type: .warmup, duration: 300)
                            ]
                        )),
                        .active(ActivePhase(
                            id: UUID(),
                            intervals: [
                                Interval(id: UUID(), name: "Sprint", type: .highIntensity, duration: 30),
                                Interval(id: UUID(), name: "Rest", type: .lowIntensity, duration: 30)
                            ]
                        )),
                        .rest(RestPhase(id: UUID(), duration: 60)),
                        .active(ActivePhase(
                            id: UUID(),
                            intervals: [
                                Interval(id: UUID(), name: "Stretching", type: .coolDown, duration: 300)
                            ]
                        ))
                    ]
                )
            ),
            reducer: { Watch_PerformWorkoutFeature() }
        )
    )
}
