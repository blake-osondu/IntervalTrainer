//
//  EI_View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/30/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


struct EditIntervalView: View {
    let store: StoreOf<EditIntervalFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                Form {
                    Section(header: Text("Interval Details")) {
                        TextField("Interval Name", text: viewStore.binding(
                            get: \.interval.name,
                            send: { .setName($0) }
                        ))
                        
                        Picker("Interval Type", selection: viewStore.binding(
                            get: \.interval.type,
                            send: { .setType($0) }
                        )) {
                            ForEach(Interval.IntervalType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        
                        DurationPicker(
                            duration: viewStore.binding(
                                get: \.interval.duration,
                                send: { .setDuration($0) }
                            )
                        )
                    }
                }
                .navigationTitle(viewStore.isNewInterval ? "Add Interval" : "Edit Interval")
                .navigationBarItems(
                    leading: Button("Cancel") { viewStore.send(.cancel) },
                    trailing: Button("Save") { viewStore.send(.save) }
                )
            }
        }
    }
}

// Preview providers
#Preview("Edit Warm Up Interval") {
    EditIntervalView(
        store: Store(
            initialState: EditIntervalFeature.State(
                interval: Interval(
                    id: UUID(),
                    name: "Light Jog",
                    type: .warmup,
                    duration: 300 // 5 minutes
                )
            ),
            reducer: {
                EditIntervalFeature()
            }
        )
    )
}

#Preview("Edit High Intensity Interval") {
    EditIntervalView(
        store: Store(
            initialState: EditIntervalFeature.State(
                interval: Interval(
                    id: UUID(),
                    name: "Sprint",
                    type: .highIntensity,
                    duration: 60 // 1 minute
                )
            ),
            reducer: {
                EditIntervalFeature()
            }
        )
    )
}

#Preview("Edit Cool Down Interval") {
    EditIntervalView(
        store: Store(
            initialState: EditIntervalFeature.State(
                interval: Interval(
                    id: UUID(),
                    name: "Stretching",
                    type: .coolDown,
                    duration: 180 // 3 minutes
                )
            ),
            reducer: {
                EditIntervalFeature()
            }
        )
    )
}

