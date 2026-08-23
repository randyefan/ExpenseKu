//
//  CardStyle.swift
//  ExpenseKu — DesignSystem
//
//  The elevated card surface every screen is built from: padding, rounded corners,
//  a hairline border, plus the warm canvas helper.
//

import SwiftUI

struct CardStyle: ViewModifier {
    var padding: CGFloat = Metric.cardPadding
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: Metric.cardRadius)
                    .fill(Theme.card)
                    .stroke(Theme.hairline, lineWidth: 1)
            }
    }
}

extension View {
    /// Elevated white/dark card with hairline border and rounded corners.
    func cardStyle(padding: CGFloat = Metric.cardPadding) -> some View {
        modifier(CardStyle(padding: padding))
    }

    /// Paints the warm canvas edge-to-edge behind this view.
    func warmBackground() -> some View {
        background(Theme.bg.ignoresSafeArea())
    }
}

#Preview {
    VStack(spacing: Metric.cardGap) {
        Text("A card").frame(maxWidth: .infinity).cardStyle()
        Text("Tighter").frame(maxWidth: .infinity).cardStyle(padding: 8)
    }
    .padding()
    .warmBackground()
}
