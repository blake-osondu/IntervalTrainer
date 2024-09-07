//
//  WorkoutCreation.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct WorkoutCreationFeature {
    @ObservableState
    struct State: Equatable {
        var workoutName: String = ""
        var intervals: IdentifiedArrayOf<Interval> = []
        @Presents var addInterval: AddIntervalFeature.State?
        @Presents var duplicateInterval: DuplicateIntervalFeature.State?
        var isMultiSelectMode: Bool = false
        var selectedIntervals: Set<Interval.ID> = []
    }
    
    @CasePathable
    enum Action {
        case cancel
        case dismiss(WorkoutPlan)
        case setWorkoutName(String)
        case addIntervalTapped
        case addInterval(PresentationAction<AddIntervalFeature.Action>)
        case deleteIntervals(IndexSet)
        case moveIntervals(IndexSet, Int)
        case toggleMultiSelectMode
        case toggleIntervalSelection(Interval.ID)
        case deleteSelectedIntervals
        case duplicateSelectedIntervalsTapped
        case duplicateInterval(PresentationAction<DuplicateIntervalFeature.Action>)
        case saveWorkoutPlan
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setWorkoutName(name):
                state.workoutName = name
                return .none
                
            case .addIntervalTapped:
                state.addInterval = AddIntervalFeature.State()
                return .none
                
            case .addInterval(.presented(.save)):
                guard let addIntervalState = state.addInterval else { return .none }
                state.intervals.append(Interval(
                    id: UUID(),
                    name: addIntervalState.name,
                    type: addIntervalState.type,
                    duration: addIntervalState.duration))
                state.addInterval = nil
                return .none
                
            case .addInterval(.dismiss):
                state.addInterval = nil
                return .none
                
            case let .deleteIntervals(indexSet):
                state.intervals.remove(atOffsets: indexSet)
                return .none
                
            case let .moveIntervals(source, destination):
                state.intervals.move(fromOffsets: source, toOffset: destination)
                return .none
                
            case .toggleMultiSelectMode:
                state.isMultiSelectMode.toggle()
                state.selectedIntervals.removeAll()
                return .none
                
            case let .toggleIntervalSelection(id):
                if state.selectedIntervals.contains(id) {
                    state.selectedIntervals.remove(id)
                } else {
                    state.selectedIntervals.insert(id)
                }
                return .none
                
            case .deleteSelectedIntervals:
                let selectedIntervals = state.selectedIntervals
                state.intervals.removeAll { selectedIntervals.contains($0.id) }
                state.selectedIntervals.removeAll()
                state.isMultiSelectMode = false
                return .none
                
            case .duplicateSelectedIntervalsTapped:
                let selectedIntervals = state.intervals.filter { state.selectedIntervals.contains($0.id) }.map { $0 }
                state.duplicateInterval = DuplicateIntervalFeature.State(intervals: selectedIntervals)
                return .none
                
            case .duplicateInterval(.presented(.confirm)):
                let newIntervals = state.selectedIntervals.flatMap { id in
                    Array(repeating: state.intervals[id: id]!, count: 1)
                }
                state.intervals.append(contentsOf: newIntervals)
                state.selectedIntervals.removeAll()
                state.isMultiSelectMode = false
                state.duplicateInterval = nil
                return .none
                
            case .duplicateInterval(.dismiss):
                state.duplicateInterval = nil
                return .none
                
            case .cancel:
                return .none
                
            case .dismiss:
                return .none
                
            case .saveWorkoutPlan:
                let newPlan = WorkoutPlan(
                    id: UUID(),
                    name: state.workoutName,
                    intervals: Array(state.intervals)
                )
               
                return .send(.dismiss(newPlan))
            case .addInterval, .duplicateInterval:
                return .none
            }
        }
        .ifLet(\.$addInterval, action: \.addInterval) {
            AddIntervalFeature()
        }
        .ifLet(\.$duplicateInterval, action: \.duplicateInterval) {
            DuplicateIntervalFeature()
        }
    }
}

struct WorkoutCreationView: View {
    let store: StoreOf<WorkoutCreationFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                List {
                    Section(header: Text("Workout Name")) {
                        TextField("Enter workout name", text: viewStore.binding(
                            get: \.workoutName,
                            send: { .setWorkoutName($0) }
                        ))
                    }
                    
                    Section(header: Text("Intervals")) {
                        ForEach(viewStore.intervals) { interval in
                            IntervalRow(interval: interval, isSelected: viewStore.selectedIntervals.contains(interval.id))
                                .onTapGesture {
                                    if viewStore.isMultiSelectMode {
                                        viewStore.send(.toggleIntervalSelection(interval.id))
                                    }
                                }
                        }
                        .onDelete { viewStore.send(.deleteIntervals($0)) }
                        .onMove { viewStore.send(.moveIntervals($0, $1)) }
                    }
                }
                .navigationTitle("Create Workout")
                .navigationBarItems(
                    leading: Button("Cancel") { viewStore.send(.cancel) },
                    trailing: Button("Save") { viewStore.send(.saveWorkoutPlan) }
                )
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Button(action: { viewStore.send(.addIntervalTapped) }) {
                            Label("Add Interval", systemImage: "plus")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { viewStore.send(.toggleMultiSelectMode) }) {
                            Text(viewStore.isMultiSelectMode ? "Done" : "Select")
                        }
                    }
                }
                .overlay(
                    Group {
                        if viewStore.isMultiSelectMode {
                            VStack {
                                Spacer()
                                HStack {
                                    Button("Delete") { viewStore.send(.deleteSelectedIntervals) }
                                    Spacer()
                                    Button("Duplicate") { viewStore.send(.duplicateSelectedIntervalsTapped) }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                        }
                    }
                )
            }
            .sheet(
                store: store.scope(state: \.$addInterval, action: \.addInterval)
            ) { addIntervalStore in
                AddIntervalView(store: addIntervalStore)
            }
            .sheet(
                store: store.scope(state: \.$duplicateInterval, action: \.duplicateInterval)
            ) { duplicateIntervalStore in
                DuplicateIntervalView(store: duplicateIntervalStore)
            }
        }
    }
}
