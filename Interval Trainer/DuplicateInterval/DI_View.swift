//
//  DI_View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/30/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


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

// Preview providers
#Preview("Duplicate High Intensity Interval") {
    DuplicateIntervalView(
        store: Store(
            initialState: DuplicateIntervalFeature.State(
                intervals: [
                    Interval(
                       id: UUID(),
                       name: "Sprint",
                       type: .highIntensity,
                       duration: 30),
                    Interval(
                       id: UUID(),
                       name: "Sprint (Copy)",
                       type: .highIntensity,
                       duration: 30
                   )
            ]),
            reducer: {
                DuplicateIntervalFeature()
            }
        )
    )
}

#Preview("Duplicate Warm Up Interval") {
    DuplicateIntervalView(
        store: Store(
            initialState: DuplicateIntervalFeature.State(
                intervals: [
                    Interval(
                        id: UUID(),
                        name: "Light Jog",
                        type: .warmup,
                        duration: 180),
                    Interval(
                        id: UUID(),
                        name: "Light Jog (Copy)",
                        type: .warmup,
                        duration: 180
                    )]
            ),
            reducer: {
                DuplicateIntervalFeature()
            }
        )
    )
}

#Preview("Duplicate Cool Down Interval") {
    DuplicateIntervalView(
        store: Store(
            initialState: DuplicateIntervalFeature.State(
                intervals: [
                    Interval(
                        id: UUID(),
                        name: "Stretching",
                        type: .coolDown,
                        duration: 300),
                    Interval(
                        id: UUID(),
                        name: "Stretching (Copy)",
                        type: .coolDown,
                        duration: 300
                    )]
            ),
            reducer: {
                DuplicateIntervalFeature()
            }
        )
    )
}



