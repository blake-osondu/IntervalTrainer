//
//  WorkoutPhase.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/7/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct IntervalRow: View {
    let interval: Interval
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(interval.name)
                    .font(.headline)
                Text(interval.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(formatDuration(interval.duration))
                .font(.subheadline)
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
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
