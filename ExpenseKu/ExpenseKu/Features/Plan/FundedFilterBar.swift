//
//  FundedFilterBar.swift
//  ExpenseKu
//
//  What stands in for the funded notice while the plan is filtered to it (L6): the
//  filter, clearable, and the total still waiting to be paid.
//

import SwiftUI

struct FundedFilterBar: View {
    let total: Decimal
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            FocusChip(title: "In the account", systemImage: "arrow.down.to.line", onClear: onClear)
            Spacer(minLength: 8)
            MoneyText(total, font: .dsSubhead, color: Theme.textSecondary)
        }
    }
}
