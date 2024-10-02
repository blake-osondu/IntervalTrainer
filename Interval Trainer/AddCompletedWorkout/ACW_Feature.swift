import Foundation
import ComposableArchitecture

@Reducer
struct AddCompletedWorkoutFeature {
    @ObservableState
    struct State: Equatable {
        var workoutName: String = ""
        var date: Date = Date()
        var duration: Double = 30.0 // Default 30 minutes
        var caloriesBurned: Double = 0.0
        var rating: Int = 3 // Default 3 out of 5
    }
    
    enum Action {
        case setWorkoutName(String)
        case setDate(Date)
        case setDuration(Double)
        case setCaloriesBurned(Double)
        case setRating(Int)
        case saveWorkout
        case cancelAddWorkout
    }
    
    @Dependency(\.dismiss) var dismiss
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setWorkoutName(name):
                state.workoutName = name
                return .none
            case let .setDate(date):
                state.date = date
                return .none
            case let .setDuration(duration):
                state.duration = duration
                return .none
            case let .setCaloriesBurned(calories):
                state.caloriesBurned = calories
                return .none
            case let .setRating(rating):
                state.rating = rating
                return .none
            case .saveWorkout:
                return .run { _ in await self.dismiss() }
            case .cancelAddWorkout:
                return .run { _ in await self.dismiss() }
            }
        }
    }
}
