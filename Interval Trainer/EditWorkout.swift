//
//  UpdateWorkoutPlan.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/9/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct EditWorkoutFeature {
    @ObservableState
    struct State: Equatable {
        var workoutPlan: WorkoutPlan
        @Presents var editPhase: EditPhaseFeature.State?
        
        init(workoutPlan: WorkoutPlan) {
            self.workoutPlan = workoutPlan
        }
    }
    
    @CasePathable
    enum Action {
        case setWorkoutName(String)
        case addPhaseTapped
        case selectedPhase(WorkoutPhase)
        case editPhase(PresentationAction<EditPhaseFeature.Action>)
        case deletePhases(IndexSet)
        case movePhases(IndexSet, Int)
        case save
        case cancel
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setWorkoutName(name):
                state.workoutPlan.name = name
                return .none
                
            case .addPhaseTapped:
                state.editPhase = EditPhaseFeature.State(phase: .active(ActivePhase(id: UUID(), intervals: [])))
                return .none
                
            case let .selectedPhase(phase):
                state.editPhase = EditPhaseFeature.State(phase: phase)
                return .none
                
            case .editPhase(.presented(.save)):
                guard let phase = state.editPhase?.phase else { return .none }
                if let index = state.workoutPlan.phases.firstIndex(where: { $0.id == phase.id }) {
                    state.workoutPlan.phases[index] = phase
                } else {
                    state.workoutPlan.phases.append(phase)
                }
                state.editPhase = nil
                return .none
                
            case .editPhase(.dismiss), .editPhase(.presented(.cancel)):
                state.editPhase = nil
                return .none
                
            case let .deletePhases(indexSet):
                state.workoutPlan.phases.remove(atOffsets: indexSet)
                return .none
                
            case let .movePhases(source, destination):
                state.workoutPlan.phases.move(fromOffsets: source, toOffset: destination)
                return .none
                
            case .save, .cancel:
                return .none
                
            case .editPhase:
                return .none
            }
        }
        .ifLet(\.$editPhase, action: \.editPhase) {
            EditPhaseFeature()
        }
    }
}

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
                        
                        Section(header: Text("Phases")) {
                            ForEach(viewStore.workoutPlan.phases) { phase in
                                PhaseRow(phase: phase)
                                    .onTapGesture {
                                        viewStore.send(.selectedPhase(phase))
                                    }
                            }
                            .onDelete { viewStore.send(.deletePhases($0)) }
                            .onMove { viewStore.send(.movePhases($0, $1)) }
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
            }
            .sheet(
                store: store.scope(state: \.$editPhase, action: \.editPhase)
            ) { editPhaseStore in
                EditPhaseView(store: editPhaseStore)
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
                    phases: [
                        .active(ActivePhase(
                            id: UUID(),
                            intervals: [
                                Interval(id: UUID(), name: "Light Jog", type: .warmup, duration: 300),
                                Interval(id: UUID(), name: "Sprint", type: .highIntensity, duration: 30),
                                Interval(id: UUID(), name: "Rest", type: .lowIntensity, duration: 30),
                                Interval(id: UUID(), name: "Stretching", type: .coolDown, duration: 300)
                            ]
                        ))
                    ]
                )
            ),
            reducer: {
                EditWorkoutFeature()
            }
        )
    )
}
