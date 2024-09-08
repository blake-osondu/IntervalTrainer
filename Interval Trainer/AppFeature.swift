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
        Scope(state: \.login, action: \.login) {
            LoginFeature()
        }
        Scope(state: \.home, action: \.home) {
            Home()
        }
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
    }
}

struct ContentView: View {
    @Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        if store.isAuthenticated {
            HomeView(store: store.scope(state: \.home, action: \.home))
        } else {
            LoginView(store: store.scope(state: \.login, action: \.login))
        }
    }
}
