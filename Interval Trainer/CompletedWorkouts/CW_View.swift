//
//  View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/29/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct CompletedWorkoutsView: View {
    let store: StoreOf<CompletedWorkoutsFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 16) {
                        ForEach(viewStore.weeklyWorkouts, id: \.weekStart) { weeklyWorkout in
                            WeeklyWorkoutSection(weeklyWorkout: weeklyWorkout)
                        }
                    }
                    .padding(.horizontal)
                    
                }
                AddCompletedWorkoutButton(action: {
                    viewStore.send(.addWorkoutButtonTapped)
                })
            }
        }
        .onAppear(perform: {
            store.send(.loadCompletedWorkouts)
        })
        .sheet(
                store: store.scope(state: \.$addWorkout, action: { .addWorkout($0) })
            ) { store in
                AddCompletedWorkoutView(store: store)
            }
    }
}

struct WeeklyWorkoutSection: View {
    let weeklyWorkout: WeeklyWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(weekTitle)
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(weeklyWorkout.workouts) { workout in
                CompletedWorkoutRow(workout: workout)
            }
        }
        .frame(width: 300)
    }
    
    private var weekTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startDate = formatter.string(from: weeklyWorkout.weekStart)
        let endDate = formatter.string(from: Calendar.current.date(byAdding: .day, value: 6, to: weeklyWorkout.weekStart)!)
        return "\(startDate) - \(endDate)"
    }
}

struct CompletedWorkoutRow: View {
    let workout: CompletedWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.name)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Text(workout.date, style: .time)
                Spacer()
                Text(formatDuration(workout.duration))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

struct AddCompletedWorkoutButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Add Workout")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

#Preview("Completed Workouts") {
    VStack {
        Spacer()
        CompletedWorkoutsView(
            store: Store(
                initialState: CompletedWorkoutsFeature.State(),
                reducer: {
                    CompletedWorkoutsFeature()
                }
            )
        )
        .frame(height: 400)
    }
}

#Preview("Weekly Workout Card") {
    let sampleWorkouts = [
        CompletedWorkout(id: UUID(), name: "Morning Run", date: Date(), duration: 1800, caloriesBurned: 300, rating: 3),
        CompletedWorkout(id: UUID(), name: "Evening Yoga", date: Date().addingTimeInterval(-86400), duration: 3600, caloriesBurned: 200, rating: 1),
        CompletedWorkout(id: UUID(), name: "HIIT Session", date: Date().addingTimeInterval(-172800), duration: 2700, caloriesBurned: 400, rating: 5)
    ]
    let weeklyWorkout = WeeklyWorkout(weekStart: Date().addingTimeInterval(-518400), workouts: sampleWorkouts)
    
    return WeeklyWorkoutSection(weeklyWorkout: weeklyWorkout)
        .padding()
}
