//
//  EP_View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/30/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct EditPhaseView: View {
    let store: StoreOf<EditPhaseFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    Form {
                        switch viewStore.phase {
                        case .active:
                            Section(header: Text("Active Phase Details")) {
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
                    switch viewStore.phase {
                    case .active:
                        VStack {
                            Spacer()
                            Button(action: {
                                viewStore.send(.addIntervalTapped)
                            }) {
                                Text("Add Interval")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    default:
                        EmptyView()
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

// Preview providers
#Preview("Edit Active Phase") {
    EditPhaseView(
        store: Store(
            initialState: EditPhaseFeature.State(
                phase: .active(ActivePhase(
                    id: UUID(),
                    intervals: [
                        Interval(id: UUID(), name: "Sprint", type: .highIntensity, duration: 30),
                        Interval(id: UUID(), name: "Jog", type: .lowIntensity, duration: 60)
                    ]
                ))
            ),
            reducer: {
                EditPhaseFeature()
            }
        )
    )
}

#Preview("Edit Rest Phase") {
    EditPhaseView(
        store: Store(
            initialState: EditPhaseFeature.State(
                phase: .rest(RestPhase(id: UUID(), duration: 120)) // 2 minutes
            ),
            reducer: {
                EditPhaseFeature()
            }
        )
    )
}

#Preview("Edit Empty Active Phase") {
    EditPhaseView(
        store: Store(
            initialState: EditPhaseFeature.State(
                phase: .active(ActivePhase(id: UUID(), intervals: []))
            ),
            reducer: {
                EditPhaseFeature()
            }
        )
    )
}
