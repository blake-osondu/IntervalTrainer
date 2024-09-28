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
        var totalElapsedTime: TimeInterval = 0
        var totalTimeRemaining: TimeInterval {
            workoutPlan.totalDuration - totalElapsedTime
        }
        @Presents var editWorkout: EditWorkoutFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var workoutComplete: WorkoutCompleteFeature.State?
        var musicPlayer: MusicPlayerFeature.State = .init()
        
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
        case editWorkoutTapped
        case editWorkout(PresentationAction<EditWorkoutFeature.Action>)
        case updateCurrentRoutine(WorkoutPlan)
        case alert(PresentationAction<Alert>)
        case workoutCompleted
        case workoutComplete(PresentationAction<WorkoutCompleteFeature.Action>)
        case musicPlayer(MusicPlayerFeature.Action)
        
        
        @CasePathable
        enum Alert: Equatable {
            case updateCurrentRoutine
            case createNewRoutine
        }
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date) var date
    
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
                state.currentPhaseIndex = 0
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
                state.currentPhaseIndex = 0
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
                state.workoutComplete = WorkoutCompleteFeature.State(totalElapsedTime: formatTime(state.totalElapsedTime))
                state.isRunning = false
                return .none
                
            case .workoutComplete(.presented(.selectedSaveWorkout)):
                let completedWorkout = CompletedWorkout(
                    id: UUID(),
                    name: state.workoutPlan.name,
                    date: self.date.now,
                    duration: state.totalElapsedTime,
                    rating: state.workoutComplete?.workoutRating ?? 0
                )
                state.workoutComplete = nil
                return .none
                //Update local database with completedworkout
                //                return .run { send in
                //                    // Simulating async upload completed workout
                //                    try await Task.sleep(for: .seconds(1))
                //
                //                    await send(.none)
                //                }
                //
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
            }
        }
        .ifLet(\.$editWorkout, action: \.editWorkout) {
            EditWorkoutFeature()
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$workoutComplete, action: \.workoutComplete) {
            WorkoutCompleteFeature()
        }
        
        Scope(state: \.musicPlayer, action: /Action.musicPlayer) {
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
        state.totalElapsedTime = max(0, state.totalElapsedTime - state.timeRemaining)
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
                    
                    HStack {
                        Text(formatTime(viewStore.totalElapsedTime))
                            .font(.system(size: 20))
                        Text("/")
                        Text(formatTime(viewStore.totalTimeRemaining))
                            .font(.system(size: 20))
                        
                    }
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
                    
                    MusicPlayerView(
                        store: store.scope(
                            state: \.musicPlayer,
                            action: { .musicPlayer($0) }
                        )
                    )
                }
                .navigationBarItems(
                    leading: Button("Cancel") { viewStore.send(.dismiss) },
                    trailing: Button("Edit") { viewStore.send(.editWorkoutTapped) }
                )
                .sheet(
                    store: store.scope(state: \.$editWorkout, action: \.editWorkout)
                ) { editWorkoutStore in
                    EditWorkoutView(store: editWorkoutStore)
                }
                .alert(
                    store: store.scope(state: \.$alert, action: \.alert)
                )
                .sheet(
                    store: store.scope(state: \.$workoutComplete, action: \.workoutComplete)) { store in
                        WorkoutCompleteView(store: store)
                    }
            }
            .padding()
        }
    }
}

extension PerformWorkoutView {
    
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
