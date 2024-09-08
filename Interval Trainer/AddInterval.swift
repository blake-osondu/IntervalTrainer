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

struct AddIntervalView: View {
    let store: StoreOf<AddIntervalFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                Form {
                    TextField("Interval Name", text: viewStore.binding(
                        get: \.name,
                        send: { .setName($0) }
                    ))
                    
                    Picker("Interval Type", selection: viewStore.binding(
                        get: \.type,
                        send: { .setType($0) }
                    )) {
                        ForEach(Interval.IntervalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    DatePicker(
                        "Duration",
                        selection: viewStore.binding(
                            get: { Date(timeIntervalSinceReferenceDate: $0.duration) },
                            send: { .setDuration($0.timeIntervalSinceReferenceDate) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }
                .navigationTitle("Add Interval")
                .navigationBarItems(
                    leading: Button("Cancel") { /* Dismiss view */ },
                    trailing: Button("Save") {
                        store.send(.save)
                    }
                )
            }
        }
    }
}

// Preview providers
#Preview("Add New Interval") {
    AddIntervalView(
        store: Store(
            initialState: AddIntervalFeature.State(),
            reducer: {
                AddIntervalFeature()
            }
        )
    )
}

#Preview("Edit Existing Interval") {
    let existingInterval = Interval(
        id: UUID(),
        name: "High Intensity Sprint",
        type: .highIntensity,
        duration: 45
    )
    
    return AddIntervalView(
        store: Store(
            initialState: AddIntervalFeature.State(name: existingInterval.name, type: existingInterval.type, duration: existingInterval.duration),
            reducer: {
                AddIntervalFeature()
            }
        )
    )
}
