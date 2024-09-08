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

struct AddPhaseView: View {
    let store: StoreOf<AddPhaseFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                Form {
                    Picker("Phase Type", selection: viewStore.binding(
                        get: \.phaseType,
                        send: { .setPhaseType($0) }
                    )) {
                        Text("Active").tag(AddPhaseFeature.PhaseType.active)
                        Text("Rest").tag(AddPhaseFeature.PhaseType.rest)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if viewStore.phaseType == .active {
                        Section(header: Text("Active Phase Details")) {
                            
                            Button("Add Interval") {
                                viewStore.send(.addIntervalTapped)
                            }
                            
                            ForEach(viewStore.intervals) { interval in
                                IntervalRow(interval: interval)
                            }
                            .onDelete { viewStore.send(.deleteInterval($0)) }
                            .onMove { viewStore.send(.moveInterval($0, $1)) }
                        }
                    } else {
                        Section(header: Text("Rest Phase Details")) {
                            DurationPicker(
                                duration: viewStore.binding(
                                    get: \.restPhaseDuration,
                                    send: { .setRestPhaseDuration($0) }
                                )
                            )
                        }
                    }
                }
                .navigationTitle("Add Phase")
                .navigationBarItems(
                    leading: Button("Cancel") { viewStore.send(.cancel) },
                    trailing: Button("Save") { viewStore.send(.save) }
                )
            }
            .sheet(
                store: store.scope(state: \.$addInterval, action: \.addInterval)
            ) { addIntervalStore in
                AddIntervalView(store: addIntervalStore)
            }
        }
    }
}

struct IntervalRow: View {
    let interval: Interval
    
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

struct DurationPicker: View {
    @Binding var duration: TimeInterval
    
    var body: some View {
        HStack {
            Text("Duration")
            Spacer()
            Picker("", selection: $duration) {
                ForEach(0..<60) { minute in
                    ForEach(0..<60) { second in
                        Text("\(minute)m \(second)s")
                            .tag(TimeInterval(minute * 60 + second))
                    }
                }
            }
            .pickerStyle(WheelPickerStyle())
        }
    }
}

// You'll need to implement AddIntervalFeature and AddIntervalView
