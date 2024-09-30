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
