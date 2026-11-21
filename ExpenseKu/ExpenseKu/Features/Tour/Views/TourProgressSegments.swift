//
//  TourProgressSegments.swift
//  ExpenseKu
//

import SwiftUI

struct TourProgressSegments: View {
    let fills: [Double]
    var track = Theme.tourTrack

    var body: some View {
        HStack(spacing: 4) {
            ForEach(fills.enumerated(), id: \.offset) { _, fill in
                Capsule()
                    .fill(track)
                    .overlay {
                        Capsule()
                            .fill(Theme.accent)
                            .scaleEffect(x: fill > 0 ? max(fill, 0.08) : 0, anchor: .leading)
                    }
                    .clipShape(.capsule)
                    .frame(height: 4)
            }
        }
        .animation(Motion.settle, value: fills)
        .accessibilityHidden(true)
    }
}
