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

    @State private var resultsHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            // Kept above the results in every state: when a narrow filter is what
            // emptied the list, the way to undo it has to be on screen.
            ExpenseSearchFilters(
                categoryNames: categoryNames,
                categoryName: $categoryName,
                range: $range
            )
            .readableColumn()

            if results.isEmpty {
                EmptyStateView(
                    title: AppLocalization.string(.noResults),
                    systemImage: "magnifyingglass",
                    message: emptyMessage
                )
            } else {
                ExpenseSearchSummary(count: results.count, total: results.total)
                    .readableColumn()

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
                .listStyle(.insetGrouped)
                .listSectionSpacing(.compact)
                .readableListMargins()
                .scrollContentBackground(.hidden)
                .background(Theme.bg)
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentSize.height } action: { _, height in
                    resultsHeight = height
                }
                .overlay(alignment: .top) {
                    Color.clear
                        .frame(height: resultsHeight)
                        .tourTarget(.searchResults, radius: Metric.cardRadius)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    /// Names the query — and any filter narrowing it — so a fruitless search
    /// explains itself instead of just going blank.
    private var emptyMessage: String {
        switch (categoryName, range == .allTime) {
        case (nil, true):
            AppLocalization.string(.emptySearchQuery(query))
        case (let category?, true):
            AppLocalization.string(.emptySearchCategory(query, category))
        case (nil, false):
            AppLocalization.string(.emptySearchPeriod(query, range.label))
        case (let category?, false):
            AppLocalization.string(.emptySearchCategoryPeriod(query, category, range.label))
        }
    }
}
