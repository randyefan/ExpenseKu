//
//  PlanOverIncomeStrip.swift
//  ExpenseKu
//
//  "Planned past your income — nothing is blocked" (frame I6).
//
//  No figure: the negative Sisa directly above already is it, and repeating it would
//  read as a second, different number. The second clause is the point — envelope
//  overspend and a negative Sisa are visual only, and the app never stops the owner
//  planning something (PRD §9.3).
//
//  Distinct from PlanDriftStrip, which is about actuals. This one is about the plan.
//

import SwiftUI

struct PlanOverIncomeStrip: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.dsCaption.weight(.semibold))
                .foregroundStyle(Theme.negative)
            Text("Planned past your income — nothing is blocked")
                .font(.dsSubhead)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.surface, in: .rect(cornerRadius: Metric.rowRadius))
    }
}
