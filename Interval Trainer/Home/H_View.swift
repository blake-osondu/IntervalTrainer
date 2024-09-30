//
//  H_View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/30/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


struct HomeView: View {
    let store: StoreOf<Home>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        
                        Text("Workout Summary")
                            .font(.system(.title2, design: .rounded).bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        WorkoutSummaryView(
                            store: store.scope(
                                state: \.workoutSummary,
                                action: \.workoutSummary
                            )
                        )
                        
                        Text("Completed Workouts")
                            .font(.system(.title2, design: .rounded).bold())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        CompletedWorkoutsView(
                            store: store.scope(
                                state: \.completedWorkouts,
                                action: \.completedWorkouts
                            )
                        )
                        Spacer().frame(height: 70)
                    }
                    .padding(.top)
                }
                
                VStack {
                    Spacer()
                    WorkoutPlansOverlay(
                        store: store.scope(
                            state: \.workoutPlans,
                            action: \.workoutPlans
                        )
                    )
                }.edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}


#Preview {
    HomeView(store: .init(initialState: Home.State(), reducer: {
        Home()
    }))
}

