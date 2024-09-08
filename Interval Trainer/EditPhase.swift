//
//  EditPhase.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/7/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct EditPhaseFeature {
    @ObservableState
    struct State: Equatable {
        var phase: WorkoutPhase
        var restPhaseDuration: TimeInterval = 60
        @Presents var editInterval: EditIntervalFeature.State?
        var intervals: IdentifiedArrayOf<Interval> = []
        
        init(phase: WorkoutPhase) {
            self.phase = phase
            switch phase {
            case .active(let activePhase):
                self.intervals = IdentifiedArray(uniqueElements: activePhase.intervals)
            case .rest(let restPhase):
                self.restPhaseDuration = restPhase.duration
            }
        }
    }
    
    @CasePathable
    enum Action {
        case setRestPhaseDuration(TimeInterval)
        case addIntervalTapped
        case intervalSelected(Interval)
        case editInterval(PresentationAction<EditIntervalFeature.Action>)
        case deleteInterval(IndexSet)
        case moveInterval(IndexSet, Int)
        case save
        case cancel
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setRestPhaseDuration(duration):
                state.restPhaseDuration = duration
                return .none
                
            case .addIntervalTapped:
                state.editInterval = EditIntervalFeature.State(
                    interval: Interval(id: UUID(), name: "", type: .warmup, duration: 60),
                    isNewInterval: true
                )
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
                
            case .editInterval(.dismiss):
                state.editInterval = nil
                return .none
                
            case let .deleteInterval(indexSet):
                state.intervals.remove(atOffsets: indexSet)
                return .none
                
            case let .moveInterval(source, destination):
                state.intervals.move(fromOffsets: source, toOffset: destination)
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
    }
}

struct EditPhaseView: View {
    let store: StoreOf<EditPhaseFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                Form {
                    switch viewStore.phase {
                    case .active:
                        Section(header: Text("Active Phase Details")) {
                           Button("Add Interval") {
                                viewStore.send(.addIntervalTapped)
                            }
                            
                            ForEach(viewStore.intervals) { interval in
                                IntervalRow(interval: interval)
                                    .onTapGesture {
                                        viewStore.send(.intervalSelected(interval))
                                    }
                            }
                            .onDelete { viewStore.send(.deleteInterval($0)) }
                            .onMove { viewStore.send(.moveInterval($0, $1)) }
                        }
                        
                    case .rest:
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
                .navigationTitle("Edit Phase")
                .navigationBarItems(
                    leading: Button("Cancel") { viewStore.send(.cancel) },
                    trailing: Button("Save") { viewStore.send(.save) }
                )
            }
            .sheet(
                store: store.scope(state: \.$editInterval, action: \.editInterval)
            ) { editIntervalStore in
                EditIntervalView(store: editIntervalStore)
            }
        }
    }
}

// Reuse IntervalRow and DurationPicker from AddPhase.swift

// You'll need to implement EditIntervalFeature and EditIntervalView
