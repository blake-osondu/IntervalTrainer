//
//  AI_View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/30/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


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

