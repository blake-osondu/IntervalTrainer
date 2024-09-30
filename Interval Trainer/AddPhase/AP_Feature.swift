//
//  AddPhase.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/7/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct AddPhaseFeature {
    @ObservableState
    struct State: Equatable {
        var phaseType: PhaseType = .active
        var restPhaseDuration: TimeInterval = 60 // Default to 1 minute
        @Presents var addInterval: AddIntervalFeature.State?
        var intervals: IdentifiedArrayOf<Interval> = []
    }
    
    enum Action {
        case setPhaseType(PhaseType)
        case setRestPhaseDuration(TimeInterval)
        case addIntervalTapped
        case addInterval(PresentationAction<AddIntervalFeature.Action>)
        case deleteInterval(IndexSet)
        case moveInterval(IndexSet, Int)
        case save
        case cancel
    }
    
    enum PhaseType {
        case active
        case rest
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setPhaseType(type):
                state.phaseType = type
                return .none
            
            case let .setRestPhaseDuration(duration):
                state.restPhaseDuration = duration
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
                
            case let .moveInterval(source, destination):
                state.intervals.move(fromOffsets: source, toOffset: destination)
                return .none
                
            case .save, .cancel:
                return .none
                
            case .addInterval:
                return .none
            }
        }
        .ifLet(\.$addInterval, action: \.addInterval) {
            AddIntervalFeature()
        }
    }
}
