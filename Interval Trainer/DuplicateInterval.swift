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

struct DuplicateIntervalView: View {
    let store: StoreOf<DuplicateIntervalFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                Form {
                    Stepper(
                        "Duplicate \(viewStore.count) time(s)",
                        value: viewStore.binding(
                            get: \.count,
                            send: { .setCount($0) }
                        ),
                        in: 1...10
                    )
                }
                .navigationTitle("Duplicate Intervals")
                .navigationBarItems(
                    leading: Button("Cancel") { /* Dismiss view */ },
                    trailing: Button("Confirm") {
                        store.send(.confirm)
                    }
                )
            }
        }
    }
}

