//
//  CycleHeader.swift
//  ExpenseKu
//
//  The Expenses tab's header card: ‹ › to page between pay cycles, the cycle's title
//  and date span, and the cycle's spending total. Spending only — the domain has no
//  income concept (Q6) — and this is the one place the coral accent lands on money.
//

import SwiftUI

struct CycleHeader: View {
    let cycle: PayCycle
    let total: Decimal
    let canGoBack: Bool
    let canGoForward: Bool
    let calendar: Calendar
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Previous cycle", systemImage: "chevron.left", action: onPrevious)
                    .labelStyle(.iconOnly)
                    .font(.body.weight(.semibold))
                    .disabled(!canGoBack)

                Spacer()

                VStack(spacing: 2) {
                    Text(cycle.title(calendar: calendar))
                        .font(.dsHeadline).bold()
                        .foregroundStyle(Theme.text)
                    Text(cycle.rangeText(calendar: calendar))
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Button("Next cycle", systemImage: "chevron.right", action: onNext)
                    .labelStyle(.iconOnly)
                    .font(.body.weight(.semibold))
                    .disabled(!canGoForward)
            }

            VStack(spacing: 4) {
                SectionHeaderText("Spending")
                MoneyText(total, font: .dsHero, color: Theme.accent)
            }
        }
        .cardStyle()
        .padding(.horizontal, Metric.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, Metric.cardGap)
    }
}
