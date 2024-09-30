//
//  View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/29/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


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
                    Text("Calories Burned: \(Int(viewStore.caloriesBurned))")
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
            .onAppear {
                viewStore.send(.startWorkout)
            }
            .onDisappear {
                viewStore.send(.endWorkout)
            }
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
