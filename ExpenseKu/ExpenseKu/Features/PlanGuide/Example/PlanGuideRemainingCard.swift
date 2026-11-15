//
//  PlanGuideRemainingCard.swift
//  ExpenseKu
//
//  The Remaining line of PlanTotalsCard on its own, for the steps that only need the
//  result (plan-guide-visual.md §4.5, Intro 3).
//

import SwiftUI

struct PlanGuideRemainingCard: View {
    let totals: PlanTotals

    var body: some View {
        HStack {
            Text(appLocalized: .remainingFunds)
                .font(.dsBody).bold()
                .foregroundStyle(Theme.text)
            Spacer(minLength: 8)
            MoneyText(totals.sisa, font: .dsBody, color: Theme.accentText)
                .layoutPriority(1)
        }
        .padding(.vertical, 8)
        .planGuideTarget(.remainingLine)
        .cardStyle()
    }
}
