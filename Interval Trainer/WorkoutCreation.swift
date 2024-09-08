//
//  WorkoutCreation.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct WorkoutCreationFeature {
    @ObservableState
    struct State: Equatable {
        var workoutName: String = ""
        var phases: IdentifiedArrayOf<WorkoutPhase> = []
        @Presents var addPhase: AddPhaseFeature.State?
        @Presents var editPhase: EditPhaseFeature.State?
    }
    
    @CasePathable
    enum Action {
        case cancel
        case dismiss(WorkoutPlan)
        case setWorkoutName(String)
        case addPhaseTapped
        case workoutPhaseSelected(WorkoutPhase)
        case addPhase(PresentationAction<AddPhaseFeature.Action>)
        case editPhase(PresentationAction<EditPhaseFeature.Action>)
        case deletePhases(IndexSet)
        case movePhases(IndexSet, Int)
        case saveWorkoutPlan
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setWorkoutName(name):
                state.workoutName = name
                return .none
                
            case .addPhaseTapped:
                state.addPhase = AddPhaseFeature.State()
                return .none
                
            case .addPhase(.presented(.save)):
                guard let addPhase = state.addPhase else { return .none }
                switch addPhase.phaseType {
                case .active:
                    let phase = WorkoutPhase.active(ActivePhase(id: UUID(), intervals: addPhase.intervals.elements))
                    state.phases.append(phase)
                case .rest:
                    let phase = WorkoutPhase.rest(RestPhase(id: UUID(), duration: addPhase.restPhaseDuration))
                    state.phases.append(phase)
                }
                state.addPhase = nil
                return .none
                
            case .addPhase(.dismiss):
                state.addPhase = nil
                return .none
                
                
            case let .workoutPhaseSelected(phase):
                state.editPhase = EditPhaseFeature.State(phase: phase)
                return .none
                
            case .editPhase(.presented(.save)):
                guard let editPhase = state.editPhase else { return .none }
                if let index = state.phases.firstIndex(where: { $0.id == editPhase.phase.id }) {
                    switch editPhase.phase {
                    case .active:
                        state.phases[index] = .active(ActivePhase(
                            id: editPhase.phase.id,
                            intervals: Array(editPhase.intervals)
                        ))
                    case .rest:
                        state.phases[index] = .rest(RestPhase(
                            id: editPhase.phase.id,
                            duration: editPhase.restPhaseDuration
                        ))
                    }
                }
                state.editPhase = nil
                return .none
                
            case .editPhase(.dismiss):
                state.editPhase = nil
                return .none
                
            case let .deletePhases(indexSet):
                state.phases.remove(atOffsets: indexSet)
                return .none
            case .cancel:
                return .none
                
            case .dismiss:    
                return .none
            case let .movePhases(source, destination):
                state.phases.move(fromOffsets: source, toOffset: destination)
                return .none
                
            case .saveWorkoutPlan:
                let newPlan = WorkoutPlan(
                    id: UUID(),
                    name: state.workoutName,
                    phases: Array(state.phases)
                )
                return .send(.dismiss(newPlan))
                
            case .addPhase, .editPhase:
                return .none
            }
        }
        .ifLet(\.$addPhase, action: \.addPhase) {
            AddPhaseFeature()
        }
        .ifLet(\.$editPhase, action: \.editPhase) {
            EditPhaseFeature()
        }
    }
}

struct WorkoutCreationView: View {
    let store: StoreOf<WorkoutCreationFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
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
                    .padding(.top, 8)
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
