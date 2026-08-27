//
//  ExpenseSearchLens.swift
//  ExpenseKu
//
//  The Expenses tab's third lens: what a query found, across every cycle. Unlike
//  the list and calendar lenses this ignores the pay cycle entirely, so it draws
//  no cycle header — the summary line is the screen's one total, and each row
//  carries its own date because the results span years.
//

import SwiftUI

struct ExpenseSearchLens: View {
    let results: ExpenseSearchResults
    let query: String
    let categoryNames: [String]
    let calendar: Calendar
    @Binding var categoryName: String?
    @Binding var range: DateRangeFilter
    let onSelect: (Expense) -> Void
    let onDelete: (IndexSet, [Expense]) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Kept above the results in every state: when a narrow filter is what
            // emptied the list, the way to undo it has to be on screen.
            ExpenseSearchFilters(
                categoryNames: categoryNames,
                categoryName: $categoryName,
                range: $range
            )

            if results.isEmpty {
                EmptyStateView(
                    title: "No results",
                    systemImage: "magnifyingglass",
                    message: emptyMessage
                )
            } else {
                ExpenseSearchSummary(count: results.count, total: results.total)

                List {
                    ForEach(results.expenses) { expense in
                        ExpenseListRow(
                            expense: expense,
                            dateLabel: SearchDateLabel.text(expense.date, calendar: calendar)
                        ) {
                            onSelect(expense)
                        }
                    }
                    .onDelete { onDelete($0, results.expenses) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Theme.bg)
            }
        }
    }

    /// Names the query — and any filter narrowing it — so a fruitless search
    /// explains itself instead of just going blank.
    private var emptyMessage: String {
        var message = "Nothing matches “\(query)”"
        if let categoryName { message += " in \(categoryName)" }
        if range != .allTime { message += " during \(range.label)" }
        return message + "."
    }
}
