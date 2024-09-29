//
//  Models.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/28/24.
//

import Foundation

public struct WorkoutPlan: Identifiable, Equatable {
    public let id: UUID
    public var name: String
    public var phases: [WorkoutPhase]
    
    public var totalDuration: TimeInterval {
        phases.reduce(0) { $0 + $1.duration }
    }
}

public enum WorkoutPhase: Identifiable, Equatable {
    case active(ActivePhase)
    case rest(RestPhase)
    
    public var id: UUID {
        switch self {
        case .active(let phase): return phase.id
        case .rest(let phase): return phase.id
        }
    }
    
    public var duration: TimeInterval {
        switch self {
        case .active(let phase): return phase.totalDuration
        case .rest(let phase): return phase.duration
        }
    }
}

public struct ActivePhase: Identifiable, Equatable {
    public let id: UUID
    public var intervals: [Interval]
    
    public var totalDuration: TimeInterval {
        intervals.reduce(0) { $0 + $1.duration }
    }
}

public struct RestPhase: Identifiable, Equatable {
    public let id: UUID
    public var duration: TimeInterval
}

// Ensure this struct is defined in your project
public struct Interval: Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var type: IntervalType
    public var duration: TimeInterval
    
    public enum IntervalType: String, CaseIterable {
        case warmup = "Warm Up"
        case highIntensity = "High Intensity"
        case lowIntensity = "Low Intensity"
        case coolDown = "Cool Down"
    }
}

public struct WorkoutState: Codable, Equatable {
    public var isRunning: Bool
    public var currentPhaseIndex: Int
    public var currentIntervalIndex: Int
    public var timeRemaining: TimeInterval
    public var totalElapsedTime: TimeInterval
    
    public func asDictionary() -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
    
    public static func fromDictionary(_ dict: [String: Any]) -> WorkoutState? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let workoutState = try? JSONDecoder().decode(WorkoutState.self, from: data) else {
            return nil
        }
        return workoutState
    }
}
