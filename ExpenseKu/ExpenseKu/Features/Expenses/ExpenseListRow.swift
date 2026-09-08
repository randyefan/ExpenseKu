//
//  ExpenseListRow.swift
//  ExpenseKu
//
//  One tappable expense row as both lenses of the Expenses tab draw it. The row no
//  longer carries its own card — it sits inside the day's ledger card — so this
//  supplies the list chrome only: the card fill, the hairline separator and the
//  press wash.
//

import SwiftUI

struct ExpenseListRow: View {
    let expense: Expense
    /// Passed through to `ExpenseRow`; only the search lens sets it.
    var dateLabel: String? = nil
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ExpenseRow(expense: expense, dateLabel: dateLabel)
                .contentShape(.rect)
        }
        .buttonStyle(.pressableRow)
        .listRowBackground(Theme.card)
        .listRowSeparatorTint(Theme.hairline)
        .listRowInsets(EdgeInsets(
            top: 0, leading: Metric.cardPadding,
            bottom: 0, trailing: Metric.cardPadding
        ))
    }
}
