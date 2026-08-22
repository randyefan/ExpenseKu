//
//  ExpenseListRow.swift
//  ExpenseKu
//
//  One tappable expense row as both lenses of the Expenses tab draw it: the shared
//  card chrome and list insets around `ExpenseRow`. Extracted so the list and the
//  calendar's selected day cannot drift apart.
//

import SwiftUI

struct ExpenseListRow: View {
    let expense: Expense
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ExpenseRow(expense: expense)
        }
        .buttonStyle(.plain)
        .cardStyle()
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(
            top: 4, leading: Metric.screenPadding,
            bottom: 4, trailing: Metric.screenPadding
        ))
    }
}
