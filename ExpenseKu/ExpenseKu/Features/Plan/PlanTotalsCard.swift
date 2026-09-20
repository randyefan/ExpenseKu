//
//  PlanTotalsCard.swift
//  ExpenseKu
//
//  The head of the plan: the income lines, then Total income, Total cost and Sisa.
//
//  Sisa appears here as a modest reconciling line, not as a hero — the cycle header
//  above already carries it at hero size, and one screen gets one hero. The two
//  annotation strips sit underneath in their own containers, each hiding when it does
//  not apply, neither of them a row of the sum.
//

import SwiftUI

struct PlanTotalsCard: View {
    let contents: PlanContents
    let onAction: (PlanAction) -> Void

    private var totals: PlanTotals { contents.totals }

    var body: some View {
        VStack(spacing: Metric.cardGap) {
            VStack(spacing: 0) {
                ForEach(contents.incomeLines) { line in
                    IncomeRow(
                        line: line,
                        onToggleArrived: { onAction(.toggleIncomeArrived(line)) },
                        onEdit: { onAction(.editIncomeLine(line)) }
                    )
                    Divider().overlay(Theme.hairline)
                }

                summaryRow("Total income", totals.totalIncome)
                summaryRow("Total cost", -totals.totalCost)

                Divider().overlay(Theme.hairline).padding(.vertical, 2)

                HStack {
                    Text("Sisa")
                        .font(.dsBody).bold()
                        .foregroundStyle(Theme.text)
                    Spacer(minLength: 8)
                    MoneyText(totals.sisa, font: .dsBody,
                              color: totals.showsOverIncome ? Theme.negative : Theme.accentText,
                              rolls: true)
                        .layoutPriority(1)
                }
                .padding(.vertical, 8)
            }
            .cardStyle()

            if totals.showsDrift {
                PlanDriftStrip(drift: totals.drift)
            }
            if totals.showsOverIncome {
                PlanOverIncomeStrip()
            }
        }
    }

    private func summaryRow(_ title: String, _ amount: Decimal) -> some View {
        HStack {
            Text(title)
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 8)
            MoneyText(amount, font: .dsSubhead, color: Theme.textSecondary)
                .layoutPriority(1)
        }
        .padding(.vertical, 6)
    }
}
