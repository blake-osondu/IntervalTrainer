//
//  DurationPicker.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 10/13/24.
//

import SwiftUI

struct DurationPicker: View {
    @Binding var duration: TimeInterval
    
    var body: some View {
        HStack {
            Text("Duration")
            Spacer()
            Picker("", selection: $duration) {
                ForEach(0..<60) { minute in
                    Text("\(minute)m")
                        .tag(TimeInterval(minute * 60))
                }
            }
            .pickerStyle(WheelPickerStyle())
            Spacer()
            Picker("", selection: $duration) {
                ForEach(0..<60) { second in
                    Text("\(second)s")
                        .tag(TimeInterval(second))
                }
            }
            .pickerStyle(WheelPickerStyle())
        }
    }
}

#Preview("Duration Picker") {
    DurationPicker(duration: .constant(600))
}
