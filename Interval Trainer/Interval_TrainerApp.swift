//
//  Interval_TrainerApp.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 8/30/24.
//
import Foundation
import SwiftUI
import ComposableArchitecture

@main
struct Interval_TrainerApp: App {
    var body: some Scene {
         WindowGroup {
             ContentView(store: Store(initialState: AppFeature.State(), reducer: {
                AppFeature()
             }))
        }
    }
}
