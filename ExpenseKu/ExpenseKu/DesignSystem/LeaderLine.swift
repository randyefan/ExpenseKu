//
//  LeaderLine.swift
//  ExpenseKu — DesignSystem
//
//  The app's one decorative motif: a dotted rule that carries the eye from a label
//  across to the figure it belongs to. Used by the day ledger header and the
//  person-detail rows. Nothing else in the app is dotted, which is what makes it
//  read as a motif rather than as texture.
//

import SwiftUI

struct LeaderLine: View {
    var body: some View {
        Line()
            .stroke(
                Theme.textSecondary.opacity(0.35),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [1, 5])
            )
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        Text("Thu, 6 August").font(.dsSubhead).bold()
        LeaderLine()
        Text("Rp 30.000").font(.dsSubhead).monospacedDigit()
    }
    .padding()
    .appBackground()
}
