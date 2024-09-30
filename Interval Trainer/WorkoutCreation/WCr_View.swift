//
//  WC_View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/30/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct WorkoutCreationView: View {
    let store: StoreOf<WorkoutCreationFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    List {
                        Section(header: Text("Workout Name")) {
                            TextField("Enter workout name", text: viewStore.binding(
                                get: \.workoutName,
                                send: { .setWorkoutName($0) }
                            ))
                        }
                        
                        Section(header: Text("Phases")) {
                            ForEach(viewStore.phases) { phase in
                                PhaseRow(phase: phase)
                                    .onTapGesture {
                                        viewStore.send(.workoutPhaseSelected(phase))
                                    }
                            }
                            .onDelete { viewStore.send(.deletePhases($0)) }
                            .onMove { viewStore.send(.movePhases($0, $1)) }
                        }
                    }
                    VStack {
                        Spacer()
                        Button(action: {
                            viewStore.send(.addPhaseTapped)
                        }) {
                            Text("Add Workout Phase")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
                .navigationTitle("Create Workout")
                .navigationBarItems(
                    leading: Button("Cancel") { viewStore.send(.cancel) },
                    trailing: Button("Save") { viewStore.send(.saveWorkoutPlan) }
                )
            }
            .sheet(
                store: store.scope(state: \.$addPhase, action: \.addPhase)
            ) { addPhaseStore in
                AddPhaseView(store: addPhaseStore)
            }
            .sheet(
                store: store.scope(state: \.$editPhase, action: \.editPhase)
            ) { editPhaseStore in
                EditPhaseView(store: editPhaseStore)
            }
        }
    }
}

struct PhaseRow: View {
    let phase: WorkoutPhase
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(phaseDetails)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(formatDuration(phase.duration))
                .font(.subheadline)
        }
    }
    
    private var phaseDetails: String {
        switch phase {
        case .active(let activePhase):
            return "\(activePhase.intervals.count) intervals"
        case .rest:
            return "Rest phase"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? ""
    }
}

// Implement AddPhaseFeature, EditPhaseFeature, AddPhaseView, and EditPhaseView

// Preview providers
#Preview("Empty Workout") {
    WorkoutCreationView(
        store: Store(
            initialState: WorkoutCreationFeature.State(),
            reducer: {
                WorkoutCreationFeature()
            }
        )
    )
}

#Preview("Workout with Phases") {
    let samplePhases: IdentifiedArrayOf<WorkoutPhase> = [
        .active(ActivePhase(
            id: UUID(),
            intervals: [
                Interval(id: UUID(), name: "Light Jog", type: .warmup, duration: 300)
            ]
        )),
        .active(ActivePhase(
            id: UUID(),
            intervals: [
                Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60),
                Interval(id: UUID(), name: "Low Intensity", type: .lowIntensity, duration: 120)
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
    
    return WorkoutCreationView(
        store: Store(
            initialState: WorkoutCreationFeature.State(
                workoutName: "Sample HIIT Workout",
                phases: samplePhases
            ),
            reducer: {
                WorkoutCreationFeature()
            }
        )
    )
}

