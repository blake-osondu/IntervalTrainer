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
        @Presents var performWorkout: PerformWorkoutFeature.State?
    }
    
    @CasePathable
    enum Action {
        case toggleExpanded
        case loadWorkoutPlans
        case workoutPlansLoaded([WorkoutPlan])
        case createNewWorkoutPlan
        case workoutCreation(PresentationAction<WorkoutCreationFeature.Action>)
        case workoutPlanSelected(WorkoutPlan)
        case performWorkout(PresentationAction<PerformWorkoutFeature.Action>)
        case addNewWorkoutPlan(WorkoutPlan)
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
                        WorkoutPlan(id: UUID(), name: "HIIT Cardio", phases: [
                            .active(ActivePhase(id: UUID(), intervals: [
                                Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300)
                            ])),
                            .active(ActivePhase(id: UUID(), intervals: [
                                Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30)
                            ])),
                            .rest(RestPhase(id: UUID(), duration: 60)),
                            .active(ActivePhase(id: UUID(), intervals: [
                                Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30)
                            ])),
                            .rest(RestPhase(id: UUID(), duration: 60)),
                            .active(ActivePhase(id: UUID(), intervals: [
                                Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                            ]))
                        ]),
                        WorkoutPlan(id: UUID(), name: "Strength Training", phases: [
                            .active(ActivePhase(id: UUID(), intervals: [
                                Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300)
                            ])),
                            .active(ActivePhase(id: UUID(), intervals: [
                                Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60)
                            ])),
                            .rest(RestPhase(id: UUID(), duration: 90)),
                            .active(ActivePhase(id: UUID(), intervals: [
                                Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60)
                            ])),
                            .rest(RestPhase(id: UUID(), duration: 90)),
                            .active(ActivePhase(id: UUID(), intervals: [
                                Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                            ]))
                        ])
                    ]
                    await send(.workoutPlansLoaded(plans))
                }
                
            case let .workoutPlansLoaded(plans):
                state.workoutPlans = plans
                return .none
                
            case .createNewWorkoutPlan:
                var workoutCreation = WorkoutCreationFeature.State()
                workoutCreation.phases = .init(
                    arrayLiteral: .active(
                        ActivePhase(
                            id: UUID(),
                            intervals: [
                                .init(id: UUID(), name: "Warmup", type: .warmup, duration: 10.0),
                                .init(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 40.0),
                                .init(id: UUID(), name: "Low Intensity", type: .lowIntensity, duration: 20.0),
                                .init(id: UUID(), name: "Cooldown", type: .coolDown, duration: 30.0)
                            ])))
                state.workoutCreation = workoutCreation
                return .none
                
            case let .workoutPlanSelected(workoutPlan):
                state.performWorkout = PerformWorkoutFeature.State(workoutPlan: workoutPlan)
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
                
            case .performWorkout(.presented(.dismiss)):
                state.performWorkout = nil
                return .none
                
            case let .addNewWorkoutPlan(newPlan):
                state.workoutPlans.append(newPlan)
                return .none
                
            case .performWorkout(.presented(.alert(.presented(.createNewRoutine)))):
                guard let updatedPlan = state.performWorkout?.editWorkout?.workoutPlan else { return .none }
                return .send(.addNewWorkoutPlan(updatedPlan))
                
            case .performWorkout:
                return .none
            
            }
        }
        .ifLet(\.$workoutCreation, action: \.workoutCreation) {
            WorkoutCreationFeature()
        }
        .ifLet(\.$performWorkout, action: \.performWorkout) {
           PerformWorkoutFeature()
        }
    }
}

extension WorkoutCreationFeature.State {
    func toWorkoutPlan() -> WorkoutPlan {
        WorkoutPlan(
            id: UUID(),
            name: self.workoutName,
            phases: Array(self.phases)
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
                                WorkoutPlanCard(plan: plan).onTapGesture {
                                    viewStore.send(.workoutPlanSelected(plan))
                                }
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
            }.fullScreenCover(
                store: store.scope(
                    state: \.$performWorkout,
                    action: \.performWorkout)) { performWorkoutStore in
                PerformWorkoutView(store: performWorkoutStore)
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
                            WorkoutPlan(id: UUID(), name: "HIIT Cardio", phases: [
                                .active(ActivePhase(id: UUID(), intervals: [
                                    Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300)
                                ])),
                                .active(ActivePhase(id: UUID(), intervals: [
                                    Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30)
                                ])),
                                .rest(RestPhase(id: UUID(), duration: 60)),
                                .active(ActivePhase(id: UUID(), intervals: [
                                    Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30)
                                ])),
                                .rest(RestPhase(id: UUID(), duration: 60)),
                                .active(ActivePhase(id: UUID(), intervals: [
                                    Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                                ]))
                            ]),
                            WorkoutPlan(id: UUID(), name: "Strength Training", phases: [
                                .active(ActivePhase(id: UUID(), intervals: [
                                    Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300)
                                ])),
                                .active(ActivePhase(id: UUID(), intervals: [
                                    Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60)
                                ])),
                                .rest(RestPhase(id: UUID(), duration: 90)),
                                .active(ActivePhase(id: UUID(), intervals: [
                                    Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60)
                                ])),
                                .rest(RestPhase(id: UUID(), duration: 90)),
                                .active(ActivePhase(id: UUID(), intervals: [
                                    Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                                ]))
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

