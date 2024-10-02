//
//  Utilities.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI

// Add this extension to apply corner radius only to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}


func organizeWorkoutsByWeek(_ workouts: [CompletedWorkout]) -> [WeeklyWorkout] {
    let calendar = Calendar.current
    let groupedWorkouts = Dictionary(grouping: workouts) { workout in
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.date))!
    }
    
    return groupedWorkouts.map { weekStart, workouts in
        WeeklyWorkout(weekStart: weekStart, workouts: workouts.sorted(by: { $0.date > $1.date }))
    }.sorted(by: { $0.weekStart > $1.weekStart })
}

func calculateStreak(workouts: [CompletedWorkout]) -> Int {
    guard let lastWorkoutDate = workouts.first?.date else { return 0 }
    let calendar = Calendar.current
    var currentDate = calendar.startOfDay(for: Date())
    var streak = 0
    var daysBack = 0
    
    while true {
        let workoutsOnThisDay = workouts.filter {
            calendar.isDate($0.date, inSameDayAs: currentDate)
        }
        
        if !workoutsOnThisDay.isEmpty {
            streak += 1
        } else if daysBack > 1 { // Allow for a 1-day gap
            break
        }
        
        daysBack += 1
        currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
    }
    
    return streak
}
