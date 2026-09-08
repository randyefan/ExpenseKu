//
//  ChipRail.swift
//  ExpenseKu — DesignSystem
//
//  The horizontal row that filter chips ride on. Chips that run past the screen
//  edge used to be sliced mid-pill, which reads as a layout bug; the rail fades
//  them out instead, so overflow announces itself as "this scrolls".
//
//  The fade is a mask rather than a gradient overlay, so it works on the canvas
//  and on a card without either one having to know the other's colour. The scroll
//  view must keep its clipping for the mask to bound the content — disabling it
//  lets chips paint past the gradient and the edge goes hard again.
//

import SwiftUI

struct ChipRail<Content: View>: View {
    var spacing: CGFloat = 8
    /// Fixed-width, not a fraction of the rail: a proportional fade dims a whole
    /// chip on a narrow screen and does nothing on a wide one.
    private let fade: CGFloat = 44
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
        .mask {
            HStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                    .frame(width: fade)
                Rectangle()
                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: fade)
            }
        }
    }
}

#Preview {
    ChipRail {
        ForEach(["All time", "This month", "This pay period", "This year", "Last 7 days"], id: \.self) { title in
            FilterChip(label: "Period", value: title)
        }
    }
    .appBackground()
}
