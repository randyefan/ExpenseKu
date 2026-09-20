//
//  PlanDriftStrip.swift
//  ExpenseKu
//
//  "Over plan so far · Rp 95.600" — actual money has run past what the plan said.
//
//  It sits under Sisa in its own container, and is deliberately **not** a fourth row
//  of the sum: Sisa keeps its definition and does not move as money is spent
//  (PRD §9.9). This reports the gap; it does not close it.
//
//  Its sibling, PlanOverIncomeStrip, states a different fact — one about the plan
//  rather than about actuals — which is why they are two components and not one strip
//  with swapped copy. Both can show at once.
//

import SwiftUI

struct PlanDriftStrip: View {
    let drift: Decimal

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up.right")
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(Theme.negative)
            Text("Over plan so far")
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 8)
            MoneyText(drift, font: .dsSubhead, color: Theme.negative)
                .layoutPriority(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.surface, in: .rect(cornerRadius: Metric.rowRadius))
    }
}
