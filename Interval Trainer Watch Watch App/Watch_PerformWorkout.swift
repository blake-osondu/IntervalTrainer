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

struct Watch_PerformWorkoutView: View {
    let store: StoreOf<PerformWorkoutFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            if viewStore.isWorkoutComplete {
                workoutCompleteView(viewStore: viewStore)
            } else {
                activeWorkoutView(viewStore: viewStore)
            }
        }
    }
    
    private func activeWorkoutView(viewStore: ViewStore<PerformWorkoutFeature.State, PerformWorkoutFeature.Action>) -> some View {
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
    
    private func workoutCompleteView(viewStore: ViewStore<PerformWorkoutFeature.State, PerformWorkoutFeature.Action>) -> some View {
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
    Watch_PerformWorkoutView(
        store: Store(
            initialState: PerformWorkoutFeature.State(
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
            reducer: { PerformWorkoutFeature() }
        )
    )
}
