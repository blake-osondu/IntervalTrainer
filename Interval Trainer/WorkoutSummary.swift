//
//  WorkoutSummary.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct WorkoutSummaryFeature {
    @ObservableState
    struct State: Equatable {
        var lastWorkoutDate: Date?
        var workoutsThisMonth: Int = 0
        var currentStreak: Int = 0
        var caloriesBurnedThisWeek: Double = 0
        var caloriesBurnedThisMonth: Double = 0
    }
    
    enum Action {
        case loadSummary
        case summaryLoaded(State)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadSummary:
                return .run { send in
                    // Simulating async load
                    try await Task.sleep(for: .seconds(1))
                    let summary = State(
                        lastWorkoutDate: Date().addingTimeInterval(-86400), // Yesterday
                        workoutsThisMonth: 15,
                        currentStreak: 5,
                        caloriesBurnedThisWeek: 1250,
                        caloriesBurnedThisMonth: 5430
                    )
                    await send(.summaryLoaded(summary))
                }
                
            case let .summaryLoaded(summary):
                state = summary
                return .none
            }
        }
    }
}

struct WorkoutSummaryView: View {
    let store: StoreOf<WorkoutSummaryFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    SummaryCard(title: "Last Workout", value: formatDate(viewStore.lastWorkoutDate))
                    SummaryCard(title: "This Month", value: "\(viewStore.workoutsThisMonth) workouts")
                }
                HStack(spacing: 16) {
                    SummaryCard(title: "Current Streak", value: "\(viewStore.currentStreak) days")
                    SummaryCard(title: "Calories This Week", value: String(format: "%.0f kcal", viewStore.caloriesBurnedThisWeek))
                }
                SummaryCard(title: "Calories This Month", value: String(format: "%.0f kcal", viewStore.caloriesBurnedThisMonth))
            }
            .padding(.horizontal)
            .onAppear {
                viewStore.send(.loadSummary)
            }
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.headline, design: .rounded).bold())
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }
}

// Preview providers
#Preview("Workout Summary - Loaded") {
    WorkoutSummaryView(
        store: Store(
            initialState: WorkoutSummaryFeature.State(
                lastWorkoutDate: Date().addingTimeInterval(-86400),
                workoutsThisMonth: 12,
                currentStreak: 3,
                caloriesBurnedThisWeek: 1250,
                caloriesBurnedThisMonth: 5430
            ),
            reducer: {
                WorkoutSummaryFeature()
            }
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Workout Summary - Loading") {
    WorkoutSummaryView(
        store: Store(
            initialState: WorkoutSummaryFeature.State(),
            reducer: {
                WorkoutSummaryFeature()
            }
        )
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
