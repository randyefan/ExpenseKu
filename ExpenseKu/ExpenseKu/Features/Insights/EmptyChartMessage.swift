//
//  EmptyChartMessage.swift
//  ExpenseKu
//
//  Stands in for a chart when the selected period has nothing to plot. Composed
//  rather than a bare line of text: a ghost of the chart it replaces, so the card
//  keeps its shape and the eye learns where the bars will appear.
//

import SwiftUI

struct EmptyChartMessage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(Theme.textSecondary.opacity(0.12))
                    .frame(width: ghostWidth(index), height: 14)
            }
            Text("No spending in this period.")
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("No spending in this period.")
    }

    private func ghostWidth(_ index: Int) -> CGFloat {
        [140, 96, 62][index]
    }
}

#Preview {
    EmptyChartMessage()
        .cardStyle()
        .padding()
        .appBackground()
}
