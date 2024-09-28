//
//  Interval_Trainer_WatchApp.swift
//  Interval Trainer Watch Watch App
//
//  Created by Blake Osonduagwueki on 9/27/24.
//

import SwiftUI
import ComposableArchitecture

@main
struct Interval_Trainer_WatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                store: Store(
                    initialState: WatchAppFeature.State(),
                    reducer: { WatchAppFeature() }
                )
            )
        }
    }
}
