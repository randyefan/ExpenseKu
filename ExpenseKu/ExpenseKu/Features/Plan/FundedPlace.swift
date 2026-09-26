//
//  FundedPlace.swift
//  ExpenseKu
//
//  "in Mandiri" — the trailing slot of a Funded row's chip line (PRD §7.6, L1): where
//  the money is waiting. Accent text rather than a chip, so it reads as the row's state
//  and not as one more tag.
//

import SwiftUI

struct FundedPlace: View {
    let account: String

    var body: some View {
        Text(PlanCopy.inAccount(account))
            .font(.dsCaption).fontWeight(.semibold)
            .foregroundStyle(Theme.accentText)
            .lineLimit(1)
            .layoutPriority(1)
    }
}
