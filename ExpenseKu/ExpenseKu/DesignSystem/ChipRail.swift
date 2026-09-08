//
//  ChipRail.swift
//  ExpenseKu — DesignSystem
//
//  The horizontal row that filter chips ride on. Chips that run past the screen
//  edge used to be sliced mid-pill, which reads as a layout bug; the rail fades
//  them out instead, so overflow announces itself as "this scrolls".
//
//  The fade is a mask rather than a gradient overlay, so it works on the cream
//  canvas and on a card without either one having to know the other's colour.
//

import SwiftUI

struct ChipRail<Content: View>: View {
    var spacing: CGFloat = 8
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: spacing) {
                content
            }
            .padding(.horizontal, Metric.screenPadding)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .mask {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.035),
                    .init(color: .black, location: 0.965),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

#Preview {
    ChipRail {
        ForEach(["All time", "This month", "This pay period", "This year", "Last 7 days"], id: \.self) { title in
            FilterChip(label: "Period", value: title)
        }
    }
    .warmBackground()
}
