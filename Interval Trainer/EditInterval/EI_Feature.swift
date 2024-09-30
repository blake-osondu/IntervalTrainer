//
//  EditInterval.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/7/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct EditIntervalFeature {
    @ObservableState
    struct State: Equatable {
        var interval: Interval
        var isNewInterval: Bool
        
        init(interval: Interval, isNewInterval: Bool = false) {
            self.interval = interval
            self.isNewInterval = isNewInterval
        }
    }
    
    enum Action {
        case setName(String)
        case setType(Interval.IntervalType)
        case setDuration(TimeInterval)
        case save
        case cancel
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setName(name):
                state.interval.name = name
                return .none
                
            case let .setType(type):
                state.interval.type = type
                return .none
                
            case let .setDuration(duration):
                state.interval.duration = duration
                return .none
                
            case .save, .cancel:
                return .none
            }
        }
    }
}
