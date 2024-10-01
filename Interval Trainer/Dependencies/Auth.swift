//
//  Auth.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/29/24.
//

import Foundation
import Dependencies
import ComposableArchitecture

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
