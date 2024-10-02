import SwiftUI
import ComposableArchitecture

struct AddCompletedWorkoutView: View {
    let store: StoreOf<AddCompletedWorkoutFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                Form {
                    Section(header: Text("Workout Details")) {
                        TextField("Workout Name", text: viewStore.binding(
                            get: \.workoutName,
                            send: { .setWorkoutName($0) }
                        ))
                        DatePicker("Date", selection: viewStore.binding(
                            get: \.date,
                            send: { .setDate($0) }
                        ), displayedComponents: [.date, .hourAndMinute])
                        Stepper(value: viewStore.binding(
                            get: \.duration,
                            send: { .setDuration($0) }
                        ), in: 1...240, step: 5) {
                            Text("Duration: \(Int(viewStore.duration)) minutes")
                        }
                        Stepper(value: viewStore.binding(
                            get: \.caloriesBurned,
                            send: { .setCaloriesBurned($0) }
                        ), in: 0...2000, step: 10) {
                            Text("Calories Burned: \(Int(viewStore.caloriesBurned))")
                        }
                        Picker("Rating", selection: viewStore.binding(
                            get: \.rating,
                            send: { .setRating($0) }
                        )) {
                            ForEach(1...5, id: \.self) { rating in
                                Text("\(rating) stars")
                            }
                        }
                    }
                }
                .navigationTitle("Add Completed Workout")
                .navigationBarItems(
                    leading: Button("Cancel") { viewStore.send(.cancelAddWorkout) },
                    trailing: Button("Save") { viewStore.send(.saveWorkout) }
                        .disabled(viewStore.workoutName.isEmpty)
                )
            }
        }
    }
}
