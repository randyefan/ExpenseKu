//
//  PlanEmptyState.swift
//  ExpenseKu
//
//  The Plan lens with no plan (frames AH3 and AH4). Carry-over no longer runs on
//  arrival (clear-plan.md §4.4), so this is what every cycle without a plan shows:
//  a copy of the latest earlier plan, or a blank one. A cleared cycle must stay
//  empty when the owner pages away and back, which an automatic copy could not allow.
//

import SwiftUI

struct PlanEmptyState: View {
    let copySourceMonth: String?
    let onCopy: () -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: Metric.cardGap) {
            EmptyStateView(
                title: AppLocalization.string(.noPlanYet),
                systemImage: "list.clipboard",
                message: PlanCopy.noPlanMessage(copyFrom: copySourceMonth)
            )

            if let copySourceMonth {
                PlanEmptyStateButton(title: AppLocalization.string(.copyFrom(copySourceMonth)), action: onCopy)
                PlanEmptyStateButton(title: AppLocalization.string(.startEmpty), isPrimary: false, action: onStart)
            } else {
                PlanEmptyStateButton(title: AppLocalization.string(.startThisCycleSPlan), action: onStart)
            }
        }
    }
}
