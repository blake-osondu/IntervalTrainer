//
//  AppFeature.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var login = LoginFeature.State()
        var home = Home.State()
        var isAuthenticated = false
    }
    
    enum Action {
        case login(LoginFeature.Action)
        case home(Home.Action)
        case setAuthenticated(Bool)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .login(.loginResponse(.success)):
                state.isAuthenticated = true
                return .none
            case .setAuthenticated(let isAuthenticated):
                state.isAuthenticated = isAuthenticated
                return .none
            default:
                return .none
            }
        }
        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }
        Scope(state: \.home, action: \.home) {
            Home()
        }
        .onChange(of: \.home.workoutPlans.performWorkout) { oldValue, newValue in
            Reduce { state, _ in
                if newValue != nil {
                    return .send(.home(.workoutPlans(.performWorkout(.presented(.syncWorkoutState)))))
                }
                return .none
            }
        }
        ._printChanges()
    }
    
    @Dependency(\.watchConnectivity) var watchConnectivity
    
    func listenForWorkoutUpdates() -> Effect<Action> {
        .run { send in
            for await message in watchConnectivity.receive() {
                if let workoutState = WorkoutState.fromDictionary(message) {
                    await send(.home(.workoutPlans(.performWorkout(.presented(.receivedWorkoutState(workoutState))))))
                }
            }
        }
    }
}

struct ContentView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        HomeView(store: store.scope(state: \.home, action: \.home))
    }
}
