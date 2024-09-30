//
//  DuplicateInterval.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/8/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


@Reducer
struct DuplicateIntervalFeature {
    @ObservableState
    struct State: Equatable {
        var intervals: [Interval]
        var count: Int = 1
    }
    
    @CasePathable
    enum Action {
        case setCount(Int)
        case confirm
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setCount(count):
                state.count = count
                return .none
            case .confirm:
                return .none
            }
        }
    }
}
