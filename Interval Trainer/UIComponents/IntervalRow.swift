//
//  IntervalRow.swift
//  Interval Trainer
//
//  Created by Blake Osonduagwueki on 10/13/24.
//

import Foundation
import SwiftUI

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
