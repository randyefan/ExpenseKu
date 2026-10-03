//
//  InsightsSpendingCard.swift
//  ExpenseKu
//
//  The window's whole total, and the split chips that filter every chart below it
//  (docs/prd/insights-drill-in.md §6.2). It wears the cycle header's look so the
//  control reads the same on both tabs. The total stays whole while filtered, as the
//  cycle header's does.
//

import SwiftUI

struct InsightsSpendingCard: View {
    let split: SpendingSplit
    let filter: PlanFilter?
    let onTap: (PlanFilter) -> Void

    var body: some View {
        VStack(spacing: 2) {
            SectionHeaderText("Spending")
            MoneyText(split.total, font: .dsHero, color: Theme.text, rolls: true)

            if PlanFilter.showsLegend(for: split, filter: filter) {
                SpendingSplitView(split: split, filter: filter, onTap: onTap)
                    .padding(.top, 12)
            }
        }
        .padding(Metric.cardPadding)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: Metric.cardRadius)
                .fill(Theme.card)
                .overlay {
                    RoundedRectangle(cornerRadius: Metric.cardRadius)
                        .fill(Theme.accent.opacity(0.05))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Metric.cardRadius)
                        .stroke(Theme.hairline, lineWidth: 1)
                }
        }
    }
}

#Preview {
    VStack(spacing: Metric.cardGap) {
        InsightsSpendingCard(split: SpendingSplit(outsidePlan: 165_000, fromPlan: 4_350_000),
                             filter: .outsidePlan, onTap: { _ in })
        InsightsSpendingCard(split: SpendingSplit(outsidePlan: 1_250_000), filter: nil, onTap: { _ in })
    }
    .padding()
    .appBackground()
}
