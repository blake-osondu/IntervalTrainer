//
//  AP_View.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 9/30/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture


struct AddPhaseView: View {
    let store: StoreOf<AddPhaseFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    Picker("Phase Type", selection: viewStore.binding(
                        get: \.phaseType,
                        send: { .setPhaseType($0) }
                    )) {
                        Text("Active").tag(AddPhaseFeature.PhaseType.active)
                        Text("Rest").tag(AddPhaseFeature.PhaseType.rest)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    Form {
                        
                        if viewStore.phaseType == .active {
                            Section(header: Text("Active Phase Details")) {
                                
                                ForEach(viewStore.intervals) { interval in
                                    IntervalRow(interval: interval)
                                }
                                .onDelete { viewStore.send(.deleteInterval($0)) }
                                .onMove { viewStore.send(.moveInterval($0, $1)) }
                            }
                        } else {
                            Section(header: Text("Rest Phase Details")) {
                                DurationPicker(
                                    duration: viewStore.binding(
                                        get: \.restPhaseDuration,
                                        send: { .setRestPhaseDuration($0) }
                                    )
                                )
                            }
                        }
                    }
                    if viewStore.phaseType == .active {
                        VStack {
                            Spacer()
                            Button(action: {
                                viewStore.send(.addIntervalTapped)
                            }) {
                                Text("Add Interval")
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
                }
                .navigationTitle("Add Phase")
                .navigationBarItems(
                    leading: Button("Cancel") { viewStore.send(.cancel) },
                    trailing: Button("Save") { viewStore.send(.save) }
                )
            }
            .sheet(
                store: store.scope(state: \.$addInterval, action: \.addInterval)
            ) { addIntervalStore in
                AddIntervalView(store: addIntervalStore)
            }
        }
    }
}

struct IntervalRow: View {
    let interval: Interval
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(interval.name)
                    .font(.headline)
                Text(interval.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(formatDuration(interval.duration))
                .font(.subheadline)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? ""
    }
}

struct DurationPicker: View {
    @Binding var duration: TimeInterval
    
    var body: some View {
        HStack {
            Text("Duration")
            Spacer()
            Picker("", selection: $duration) {
                ForEach(0..<60) { minute in
                    ForEach(0..<60) { second in
                        Text("\(minute)m \(second)s")
                            .tag(TimeInterval(minute * 60 + second))
                    }
                }
            }
            .pickerStyle(WheelPickerStyle())
        }
    }
}

// You'll need to implement AddIntervalFeature and AddIntervalView
// Preview providers
#Preview("Add Active Phase") {
    AddPhaseView(
        store: Store(
            initialState: AddPhaseFeature.State(
                phaseType: .active,
                intervals: [
                    Interval(id: UUID(), name: "Sprint", type: .highIntensity, duration: 30),
                    Interval(id: UUID(), name: "Jog", type: .lowIntensity, duration: 60)
                ]
            ),
            reducer: {
                AddPhaseFeature()
            }
        )
    )
}

#Preview("Add Rest Phase") {
    AddPhaseView(
        store: Store(
            initialState: AddPhaseFeature.State(
                phaseType: .rest,
                restPhaseDuration: 120 // 2 minutes
            ),
            reducer: {
                AddPhaseFeature()
            }
        )
    )
}


#Preview("Empty Active Phase") {
    AddPhaseView(
        store: Store(
            initialState: AddPhaseFeature.State(phaseType: .active),
            reducer: {
                AddPhaseFeature()
            }
        )
    )
}

