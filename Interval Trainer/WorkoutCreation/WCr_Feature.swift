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
        var intervals: IdentifiedArrayOf<Interval> = []
        @Presents var addInterval: AddIntervalFeature.State?
        @Presents var editInterval: EditIntervalFeature.State?
    }
    
    @CasePathable
    enum Action {
        case cancel
        case dismiss(WorkoutPlan)
        case setWorkoutName(String)
        case intervalSelected(Interval)
        case saveWorkoutPlan
        case addIntervalTapped
        case addInterval(PresentationAction<AddIntervalFeature.Action>)
        case deleteInterval(IndexSet)
        case moveInterval(IndexSet, Int)
        case editInterval(PresentationAction<EditIntervalFeature.Action>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setWorkoutName(name):
                state.workoutName = name
                return .none
                
            case .addIntervalTapped:
                state.addInterval = AddIntervalFeature.State()
                return .none
                
            case .addInterval(.presented(.save)):
                guard let addInterval = state.addInterval else { return .none }
                let interval = Interval(id: UUID(),
                                        name: addInterval.name,
                                        type: addInterval.type,
                                        duration: addInterval.duration)
                state.intervals.append(interval)
                state.addInterval = nil
                return .none
                
            case .addInterval(.dismiss):
                state.addInterval = nil
                return .none
                
            case let .deleteInterval(indexSet):
                state.intervals.remove(atOffsets: indexSet)
                return .none
            
            case .addInterval:
                return .none
            
            case let .moveInterval(source, destination):
                state.intervals.move(fromOffsets: source, toOffset: destination)
                return .none
            
            case let .intervalSelected(interval):
                state.editInterval = EditIntervalFeature.State(interval: interval)
                return .none
            
            case .editInterval(.presented(.save)):
                guard let interval = state.editInterval?.interval else { return .none }
                if let index = state.intervals.firstIndex(where: { $0.id == interval.id }) {
                    state.intervals[index] = interval
                } else {
                    state.intervals.append(interval)
                }
                state.editInterval = nil
                return .none
                
            case .editInterval(.dismiss), .editInterval(.presented(.cancel)):
                state.editInterval = nil
                return .none
             
            case .cancel:
                return .none
                
            case .dismiss:    
                return .none
                
            case .saveWorkoutPlan:
                let newPlan = WorkoutPlan(
                    id: UUID(),
                    name: state.workoutName,
                    intervals: Array(state.intervals)
                )
                return .send(.dismiss(newPlan))
            
            case .editInterval:
                return .none
            }
        }
        .ifLet(\.$addInterval, action: \.addInterval) {
            AddIntervalFeature()
        }
        .ifLet(\.$editInterval, action: \.editInterval) {
            EditIntervalFeature()
        }
    }
}
