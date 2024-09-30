//
//  Login.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct LoginFeature {
    @ObservableState
    struct State: Equatable {
        var email = ""
        var password = ""
        var isLoading = false
        var errorMessage: String?
    }
    
    enum Action {
        case emailChanged(String)
        case passwordChanged(String)
        case loginButtonTapped
        case loginResponse(Result<Bool, Error>)
        case didSelectForgotPassword
        case didSelectSignUp
    }
    
    @Dependency(\.authClient) var authClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .emailChanged(let email):
                state.email = email
                return .none
            case .passwordChanged(let password):
                state.password = password
                return .none
            case .loginButtonTapped:
                guard isValidEmail(state.email) else {
                    state.errorMessage = "Invalid email format"
                    return .none
                }
                guard !state.password.isEmpty else {
                    state.errorMessage = "Password cannot be empty"
                    return .none
                }
                state.isLoading = true
                state.errorMessage = nil
                return .run { [email = state.email, password = state.password] send in
                    let result = try await authClient.login(email, password)
                    await send(.loginResponse(.success(result)))
                } catch: { error, send in
                    await send(.loginResponse(.failure(error)))
                }
            case .loginResponse(.success):
                state.isLoading = false
                return .none
            case .loginResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            case .didSelectSignUp:
                // Navigate to Sign Up
                return .none
            case .didSelectForgotPassword:
                // Handle forgotten password recovery
                return .none
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
