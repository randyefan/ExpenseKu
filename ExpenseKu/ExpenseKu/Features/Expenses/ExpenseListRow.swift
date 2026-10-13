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
    /// Set in the List lens's Select mode, where a tap checks the row instead of
    /// opening it (envelope-assignment.md §4.6).
    var selectionMark: SelectionMark? = nil
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                if let selectionMark {
                    SelectionCircle(mark: selectionMark)
                }
                ExpenseRow(expense: expense, dateLabel: dateLabel)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.pressableRow)
        .disabled(selectionMark == .unavailable)
        .opacity(selectionMark == .unavailable ? 0.4 : 1)
        .accessibilityAddTraits(selectionMark == .on ? .isSelected : [])
        .listRowBackground(Theme.card)
        .listRowSeparatorTint(Theme.hairline)
        .listRowInsets(EdgeInsets(
            top: 0, leading: Metric.cardPadding,
            bottom: 0, trailing: Metric.cardPadding
        ))
    }
}
