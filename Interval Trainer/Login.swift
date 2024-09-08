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

struct LoginView: View {
    @Bindable var store: StoreOf<LoginFeature>
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Login")
                    .foregroundColor(.black)
                    .font(.headline)
                Spacer()
                TextField("Email", text: $store.email.sending(\.emailChanged))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $store.password.sending(\.passwordChanged))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                Button("Login") {
                    store.send(.loginButtonTapped)
                }
                .disabled(store.isLoading)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal, 20)
                
                Button("Sign Up") {
                    store.send(.didSelectSignUp)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal, 20)
                
                Button("Forgot Password") {
                    store.send(.didSelectForgotPassword)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal, 20)
                
                if store.isLoading {
                    ProgressView()
                }

                Spacer()
            }
            .padding()

        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
// Dependency for authentication
struct AuthClient {
    var login: @Sendable (String, String) async throws -> Bool
}

extension DependencyValues {
    var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}

extension AuthClient: DependencyKey {
    static let liveValue = AuthClient(
        login: { email, password in
            // Simulate network request
            try await Task.sleep(for: .seconds(1))
            // For demo purposes, always return true
            return true
        }
    )
}

#Preview("Default State") {
    LoginView(
        store: Store(
            initialState: LoginFeature.State(),
            reducer: {
                LoginFeature()
            }
        )
    )
}

#Preview("Loading State") {
    LoginView(
        store: Store(
            initialState: LoginFeature.State(isLoading: true),
            reducer: {
                LoginFeature()
            }
        )
    )
}

#Preview("Error State") {
    LoginView(
        store: Store(
            initialState: LoginFeature.State(errorMessage: "Invalid username or password"),
            reducer: {
                LoginFeature()
            }
        )
    )
}
