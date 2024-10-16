//
//  View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/29/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture

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
                            WorkoutPlan(id: UUID(), name: "HIIT Cardio", intervals: [
                                    Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300),
                                    Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30),
                                    Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 30),
                                    Interval(id: UUID(), name: "Cool Down", type: .coolDown, duration: 300)
                            ]),
                            WorkoutPlan(id: UUID(), name: "Strength Training", intervals: [
                                    Interval(id: UUID(), name: "Warm Up", type: .warmup, duration: 300),
                                    Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60),
                                    Interval(id: UUID(), name: "High Intensity", type: .highIntensity, duration: 60),
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

