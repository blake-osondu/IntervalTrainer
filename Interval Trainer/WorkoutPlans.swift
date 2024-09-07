//
//  WorkoutPlans.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/3/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

@Reducer
struct WorkoutPlansFeature {
    @ObservableState
    struct State: Equatable {
        var workoutPlans: [WorkoutPlan] = []
        var isExpanded = false
        @Presents var workoutCreation: WorkoutCreationFeature.State?
    }
    
    enum Action {
        case toggleExpanded
        case loadWorkoutPlans
        case workoutPlansLoaded([WorkoutPlan])
        case createNewWorkoutPlan
        case workoutCreation(PresentationAction<WorkoutCreationFeature.Action>)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .toggleExpanded:
                state.isExpanded.toggle()
                return .none
                
            case .loadWorkoutPlans:
                return .run { send in
                    // Simulating async load
                    try await Task.sleep(for: .seconds(1))
                    let plans = [
                        WorkoutPlan(id: UUID(), name: "HIIT Cardio", intervals: [
                            Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300),
                            Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30),
                            Interval(id: UUID(), name: "Low Intensity", type: .lowIntensity, duration: 60),
                            Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30),
                            Interval(id: UUID(), name: "Low Intensity", type: .lowIntensity, duration: 60),
                            Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                        ]),
                        WorkoutPlan(id: UUID(), name: "Strength Training", intervals: [
                            Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300),
                            Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60),
                            Interval(id: UUID(), name: "Rest", type: .rest, duration: 90),
                            Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60),
                            Interval(id: UUID(), name: "Rest", type: .rest, duration: 90),
                            Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                        ])
                    ]
                    await send(.workoutPlansLoaded(plans))
                }
                
            case let .workoutPlansLoaded(plans):
                state.workoutPlans = plans
                return .none
                
            case .createNewWorkoutPlan:
                state.workoutCreation = WorkoutCreationFeature.State()
                return .none
                
            case .workoutCreation(.presented(.dismiss(let newPlan))):
                state.workoutPlans.append(newPlan)
                state.workoutCreation = nil
                return .none
                
            case .workoutCreation(.presented(.cancel)):
                state.workoutCreation = nil
                return .none
                
            case .workoutCreation:
                return .none
            }
        }
        .ifLet(\.$workoutCreation, action: \.workoutCreation) {
            WorkoutCreationFeature()
        }
    }
}

extension WorkoutCreationFeature.State {
    func toWorkoutPlan() -> WorkoutPlan {
        WorkoutPlan(
            id: UUID(),
            name: self.workoutName,
            intervals: Array(self.intervals)
        )
    }
}

struct WorkoutPlansOverlay: View {
    let store: StoreOf<WorkoutPlansFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                if viewStore.isExpanded {
                    Spacer()
                }
                HStack {
                    Text("Workout Plans")
                        .font(.system(.title3, design: .rounded).bold())
                    Spacer()
                    Button(action: { viewStore.send(.toggleExpanded) }) {
                        Image(systemName: viewStore.isExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                if viewStore.isExpanded {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewStore.workoutPlans) { plan in
                                WorkoutPlanCard(plan: plan)
                            }
                            
                            Button(action: {
                                viewStore.send(.createNewWorkoutPlan)
                            }) {
                                Text("Create New Workout Plan")
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
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color(.systemBackground))
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: -4)
            .onAppear(perform: {
                viewStore.send(.loadWorkoutPlans)
            })
            .sheet(
                store: store.scope(
                    state: \.$workoutCreation,
                    action: \.workoutCreation
                )
            ) { workoutCreationStore in
                WorkoutCreationView(store: workoutCreationStore)
            }
        }
    }
}

struct WorkoutPlanCard: View {
    let plan: WorkoutPlan
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
                Text("Duration: \(formatDuration(plan.totalDuration))")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
}

// Add this preview provider at the end of the file
#Preview {
    ZStack {
        Color.gray.opacity(0.3).edgesIgnoringSafeArea(.all)
        VStack {
            Spacer()
            WorkoutPlansOverlay(
                store: Store(
                    initialState: WorkoutPlansFeature.State(
                        workoutPlans: [
                            WorkoutPlan(id: UUID(), name: "HIIT Cardio", intervals: [
                                Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300),
                                Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30),
                                Interval(id: UUID(), name: "Low Intensity", type: .lowIntensity, duration: 60),
                                Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                            ]),
                            WorkoutPlan(id: UUID(), name: "Strength Training", intervals: [
                                Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300),
                                Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60),
                                Interval(id: UUID(), name: "Rest", type: .rest, duration: 90),
                                Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                            ])
                        ],
                        isExpanded: true
                    )
                ) {
                    WorkoutPlansFeature()
                }
            )
        }.edgesIgnoringSafeArea(.bottom)
    }
}

// Assuming you have these structures defined elsewhere
struct WorkoutPlan: Identifiable, Equatable {
    let id: UUID
    let name: String
    let intervals: [Interval]
    
    var totalDuration: TimeInterval {
        intervals.reduce(0) { $0 + $1.duration }
    }
}

struct Interval: Identifiable, Equatable {
    let id: UUID
    var name: String
    var type: IntervalType
    var duration: TimeInterval
    
    enum IntervalType: String, CaseIterable {
        case warmup = "Warm Up"
        case highIntensity = "High Intensity"
        case lowIntensity = "Low Intensity"
        case rest = "Rest"
        case coolDown = "Cool Down"
    }
}
