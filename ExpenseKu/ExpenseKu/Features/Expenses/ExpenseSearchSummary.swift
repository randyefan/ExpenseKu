//
//  ExpenseSearchSummary.swift
//  ExpenseKu
//
//  What a search found: how many, and how much. The total takes the coral hero
//  treatment only because the cycle total is hidden while a query is active —
//  one hero number per screen, never two.
//

import SwiftUI

struct ExpenseSearchSummary: View {
    let count: Int
    let total: Decimal

    private var countText: String {
        count == 1 ? "1 result" : "\(count) results"
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(countText)
                .font(.dsSubhead)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.textSecondary)

            Spacer(minLength: 8)

            MoneyText(total, font: .dsTitle, color: Theme.accent)
        }
        .padding(.horizontal, Metric.screenPadding)
        .padding(.bottom, Metric.cardGap)
    }
}

#Preview {
    VStack(spacing: Metric.cardGap) {
        ExpenseSearchSummary(count: 12, total: 340_000)
        ExpenseSearchSummary(count: 1, total: 22_000)
    }
    .warmBackground()
}

#Preview("Gelap") {
    ExpenseSearchSummary(count: 12, total: 340_000)
        .warmBackground()
        .preferredColorScheme(.dark)
}
