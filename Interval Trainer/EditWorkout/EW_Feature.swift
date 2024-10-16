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
        @Presents var addInterval: AddIntervalFeature.State?
        @Presents var editInterval: EditIntervalFeature.State?

        init(workoutPlan: WorkoutPlan) {
            self.workoutPlan = workoutPlan
        }
    }
    
    @CasePathable
    enum Action {
        case setWorkoutName(String)
        case intervalSelected(Interval)
        case addIntervalTapped
        case addInterval(PresentationAction<AddIntervalFeature.Action>)
        case deleteInterval(IndexSet)
        case moveInterval(IndexSet, Int)
        case editInterval(PresentationAction<EditIntervalFeature.Action>)
        case save
        case cancel
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setWorkoutName(name):
                state.workoutPlan.name = name
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
                state.workoutPlan.intervals.append(interval)
                state.addInterval = nil
                return .none
                
            case .addInterval(.dismiss):
                state.addInterval = nil
                return .none
                
            case let .deleteInterval(indexSet):
                state.workoutPlan.intervals.remove(atOffsets: indexSet)
                return .none
            
            case .addInterval:
                return .none
            
            case let .moveInterval(source, destination):
                state.workoutPlan.intervals.move(fromOffsets: source, toOffset: destination)
                return .none
            
            case let .intervalSelected(interval):
                state.editInterval = EditIntervalFeature.State(interval: interval)
                return .none
            
            case .editInterval(.presented(.save)):
                guard let interval = state.editInterval?.interval else { return .none }
                if let index = state.workoutPlan.intervals.firstIndex(where: { $0.id == interval.id }) {
                    state.workoutPlan.intervals[index] = interval
                } else {
                    state.workoutPlan.intervals.append(interval)
                }
                state.editInterval = nil
                return .none
                
            case .editInterval(.dismiss), .editInterval(.presented(.cancel)):
                state.editInterval = nil
                return .none
                
            case .save, .cancel:
                return .none
                
            case .editInterval:
                return .none
            }
        }
        .ifLet(\.$editInterval, action: \.editInterval) {
            EditIntervalFeature()
        }
        .ifLet(\.$addInterval, action: \.addInterval) {
            AddIntervalFeature()
        }
    }
}
