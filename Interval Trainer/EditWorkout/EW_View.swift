//
//  EW_View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/30/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


struct EditWorkoutView: View {
    let store: StoreOf<EditWorkoutFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    List {
                        Section(header: Text("Workout Name")) {
                            TextField("Enter workout name", text: viewStore.binding(
                                get: \.workoutPlan.name,
                                send: { .setWorkoutName($0) }
                            ))
                        }
                        
                        Section(header: Text("Intervals")) {
                            ForEach(viewStore.workoutPlan.intervals) { interval in
                                IntervalRow(interval: interval)
                                    .onTapGesture {
                                        viewStore.send(.intervalSelected(interval))
                                    }
                            }
                            .onDelete { viewStore.send(.deleteInterval($0)) }
                            .onMove { viewStore.send(.moveInterval($0, $1)) }
                        }
                    }
                    .navigationTitle("Edit Workout")
                    .navigationBarItems(
                        leading: Button("Cancel") { viewStore.send(.cancel) },
                        trailing: Button("Save") { viewStore.send(.save) }
                    )
                    VStack {
                        Spacer()
                        Button(action: {
                            viewStore.send(.addIntervalTapped)
                        }) {
                            Text("Add Interval")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .sheet(
                store: store.scope(state: \.$addInterval, action: \.addInterval)
            ) { addIntervalStore in
                AddIntervalView(store: addIntervalStore)
            }
            .sheet(
                store: store.scope(state: \.$editInterval, action: \.editInterval)
            ) { editIntervalStore in
                EditIntervalView(store: editIntervalStore)
            }
        }
    }
}

// ... (PhaseRow implementation)

// Preview provider
#Preview("Edit Workout") {
    EditWorkoutView(
        store: Store(
            initialState: EditWorkoutFeature.State(
                workoutPlan: WorkoutPlan(
                    id: UUID(),
                    name: "HIIT Workout",
                    intervals: [
                                Interval(id: UUID(), name: "Light Jog", type: .warmup, duration: 300),
                                Interval(id: UUID(), name: "Sprint", type: .highIntensity, duration: 30),
                                Interval(id: UUID(), name: "Rest", type: .lowIntensity, duration: 30),
                                Interval(id: UUID(), name: "Stretching", type: .coolDown, duration: 300)
                            ]
                )
            ),
            reducer: {
                EditWorkoutFeature()
            }
        )
    )
}

