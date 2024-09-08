//
//  CompletedWorkouts.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
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
                    viewStore.send(.addCompletedWorkoutTapped)
                })
            }
        }
        .onAppear(perform: {
            store.send(.loadCompletedWorkouts)
        })
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

struct WeeklyWorkout: Equatable {
    let weekStart: Date
    let workouts: [CompletedWorkout]
}

@Reducer
struct CompletedWorkoutsFeature {
    @ObservableState
    struct State: Equatable {
        var weeklyWorkouts: [WeeklyWorkout] = []
    }
    
    enum Action {
        case loadCompletedWorkouts
        case completedWorkoutsLoaded([CompletedWorkout])
        case addCompletedWorkoutTapped
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadCompletedWorkouts:
                return .run { send in
                    let workouts = generateSampleWorkouts()
                    await send(.completedWorkoutsLoaded(workouts))
                }
                
            case let .completedWorkoutsLoaded(workouts):
                state.weeklyWorkouts = organizeWorkoutsByWeek(workouts)
                return .none
                
            case .addCompletedWorkoutTapped:
                // Handle tapping the add completed workout button
                return .none
            }
        }
    }
    
    private func generateSampleWorkouts() -> [CompletedWorkout] {
        let calendar = Calendar.current
        let now = Date()
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
        
        var workouts: [CompletedWorkout] = []
        var currentDate = threeMonthsAgo
        
        while currentDate <= now {
            let workoutsThisWeek = Int.random(in: 0...5)  // 0 to 5 workouts per week
            
            for _ in 0..<workoutsThisWeek {
                let workoutDate = calendar.date(byAdding: .hour, value: Int.random(in: 0...23), to: currentDate)!
                let workout = CompletedWorkout(
                    id: UUID(),
                    name: randomWorkoutName(),
                    date: workoutDate,
                    duration: TimeInterval(Int.random(in: 15...120) * 60)  // 15 to 120 minutes
                )
                workouts.append(workout)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate)!
        }
        
        return workouts
    }
    
    private func randomWorkoutName() -> String {
        let workoutTypes = ["Run", "Yoga", "HIIT", "Strength Training", "Cycling", "Swimming", "Pilates", "Boxing"]
        let modifiers = ["Morning", "Evening", "Intense", "Relaxing", "Quick", "Extended"]
        
        let type = workoutTypes.randomElement()!
        let modifier = modifiers.randomElement()!
        
        return "\(modifier) \(type)"
    }
    
    private func organizeWorkoutsByWeek(_ workouts: [CompletedWorkout]) -> [WeeklyWorkout] {
        let calendar = Calendar.current
        let groupedWorkouts = Dictionary(grouping: workouts) { workout in
            calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.date))!
        }
        
        return groupedWorkouts.map { weekStart, workouts in
            WeeklyWorkout(weekStart: weekStart, workouts: workouts.sorted(by: { $0.date > $1.date }))
        }.sorted(by: { $0.weekStart > $1.weekStart })
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
        CompletedWorkout(id: UUID(), name: "Morning Run", date: Date(), duration: 1800),
        CompletedWorkout(id: UUID(), name: "Evening Yoga", date: Date().addingTimeInterval(-86400), duration: 3600),
        CompletedWorkout(id: UUID(), name: "HIIT Session", date: Date().addingTimeInterval(-172800), duration: 2700)
    ]
    let weeklyWorkout = WeeklyWorkout(weekStart: Date().addingTimeInterval(-518400), workouts: sampleWorkouts)
    
    return WeeklyWorkoutSection(weeklyWorkout: weeklyWorkout)
        .padding()
}
