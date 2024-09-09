//
//  PerformWorkout.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/8/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct PerformWorkoutFeature {
    @ObservableState
    struct State: Equatable {
        var workoutPlan: WorkoutPlan
        var currentPhaseIndex: Int = 0
        var currentIntervalIndex: Int = 0
        var timeRemaining: TimeInterval = 0
        var isRunning: Bool = false
        
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
    }
    
    @CasePathable
    enum Action {
        case timerTick
        case toggleRunning
        case skipInterval
        case rewindInterval
        case stopWorkout
        case dismiss
    }
    
    @Dependency(\.continuousClock) var clock
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {

            case .timerTick:
                guard state.isRunning else { return .none }
                state.timeRemaining -= 1
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
                
            case .rewindInterval:
                return rewindToPreviousInterval(&state)
                
            case .stopWorkout:
                state.isRunning = false
                state.currentPhaseIndex = 0
                state.currentIntervalIndex = 0
                state.timeRemaining = state.currentInterval?.duration ?? 0
                return .none
                
            case .dismiss:
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
            return .send(.stopWorkout)
        }
        
        if state.currentPhaseIndex >= state.workoutPlan.phases.count {
            return .send(.stopWorkout)
        }
        
        state.timeRemaining = state.currentInterval?.duration ?? 0
        return .none
    }
    
    private func rewindToPreviousInterval(_ state: inout State) -> Effect<Action> {
        if state.currentIntervalIndex > 0 {
            state.currentIntervalIndex -= 1
        } else if state.currentPhaseIndex > 0 {
            state.currentPhaseIndex -= 1
            switch state.currentPhase {
            case .active(let activePhase):
                state.currentIntervalIndex = activePhase.intervals.count - 1
            case .rest:
                state.currentIntervalIndex = 0
            case .none:
                break
            }
        }
        
        state.timeRemaining = state.currentInterval?.duration ?? 0
        return .none
    }
}

struct PerformWorkoutView: View {
    let store: StoreOf<PerformWorkoutFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                VStack(spacing: 20) {
                    Text(viewStore.workoutPlan.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    
                    Text(viewStore.currentInterval?.name ?? "")
                        .font(.title2)
                    
                    Spacer()
                    
                    Text(formatTime(viewStore.timeRemaining))
                        .font(.system(size: 100, weight: .bold, design: .monospaced))
                    
                    Spacer()
                    
                    HStack(spacing: 70) {
                        Button(action: { viewStore.send(.rewindInterval) }) {
                            Image(systemName: "backward.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .font(.title)
                        }
                        
                        Button(action: { viewStore.send(.toggleRunning) }) {
                            Image(systemName: viewStore.isRunning ? "pause.fill" : "play.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .font(.largeTitle)
                        }
                        
                        Button(action: { viewStore.send(.skipInterval) }) {
                            Image(systemName: "forward.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .font(.title)
                        }
                    }
                    
                    Button("Stop Workout") {
                        viewStore.send(.stopWorkout)
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .navigationBarItems(
                    leading: Button("Cancel") { viewStore.send(.dismiss) }
                )
            }
            .padding()
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Preview providers
#Preview("Perform Workout") {
    PerformWorkoutView(
        store: Store(
            initialState: PerformWorkoutFeature.State(
                workoutPlan: WorkoutPlan(
                    id: UUID(),
                    name: "HIIT Workout",
                    phases: [
                        .active(ActivePhase(
                            id: UUID(),
                            intervals: [
                                Interval(id: UUID(), name: "Light Jog", type: .lowIntensity, duration: 300),
                                Interval(id: UUID(), name: "Sprint", type: .highIntensity, duration: 30),
                                Interval(id: UUID(), name: "Light Jog", type: .lowIntensity, duration: 300),
                                Interval(id: UUID(), name: "Sprint", type: .highIntensity, duration: 30),
                                Interval(id: UUID(), name: "Light Jog", type: .lowIntensity, duration: 300),
                                Interval(id: UUID(), name: "Sprint", type: .highIntensity, duration: 30),
                                Interval(id: UUID(), name: "Light Jog", type: .lowIntensity, duration: 300),
                                Interval(id: UUID(), name: "Sprint", type: .highIntensity, duration: 30),
                                Interval(id: UUID(), name: "Light Jog", type: .lowIntensity, duration: 300)
                            ]
                        )),
                        .active(ActivePhase(
                            id: UUID(),
                            intervals: [
                                Interval(id: UUID(), name: "Stretching", type: .coolDown, duration: 300)
                            ]
                        ))
                    ]
                )
            ),
            reducer: {
                PerformWorkoutFeature()
            }
        )
    )
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
