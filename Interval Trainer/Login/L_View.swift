//
//  LoginView.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/29/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

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
