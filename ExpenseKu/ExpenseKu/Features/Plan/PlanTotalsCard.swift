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
    let payday: Int
    let calendar: Calendar
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
                if let label = totals.paidEarly.outgoingLabel(payday: payday, calendar: calendar) {
                    paidEarlyRow(label, -totals.paidEarly.outgoing)
                }
                if let label = totals.paidEarly.incomingLabel(payday: payday, calendar: calendar) {
                    paidEarlyRow(label, totals.paidEarly.incoming)
                }

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

    private func paidEarlyRow(_ title: String, _ amount: Decimal) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.forward")
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(Theme.plan)
                .accessibilityHidden(true)
            Text(title)
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 8)
            HStack(spacing: 2) {
                if amount > 0 {
                    Text(verbatim: "+").font(.dsSubhead).bold()
                }
                MoneyText(amount, font: .dsSubhead, color: Theme.textSecondary)
            }
            .foregroundStyle(Theme.textSecondary)
            .layoutPriority(1)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
