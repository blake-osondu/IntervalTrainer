//
//  AddInterval.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/7/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct AddIntervalFeature {
    @ObservableState
    struct State: Equatable {
        var name: String = ""
        var type: Interval.IntervalType = .warmup
        var duration: TimeInterval = 60
    }
    
    @CasePathable
    enum Action {
        case setName(String)
        case setType(Interval.IntervalType)
        case setDuration(TimeInterval)
        case save
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setName(name):
                state.name = name
                return .none
            case let .setType(type):
                state.type = type
                return .none
            case let .setDuration(duration):
                state.duration = duration
                return .none
            case .save:
                return .none
            }
        }
    }
}
