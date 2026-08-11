//
//  ExpenseDayGrouping.swift
//  ExpenseKu
//
//  Pure grouping/sort used by the expenses list: bucket expenses by calendar day
//  (most recent day first) and, within each day, order by full timestamp so the
//  time the user set on an expense drives its position. Extracted from ExpensesView
//  as the behaviour oracle for the "sort by time" feature (see
//  .scratch/features/expense-time/). No SwiftUI, no side effects — unit-testable.
//

import Foundation

/// One calendar day's worth of expenses, newest-time first.
struct ExpenseDayGroup {
    /// Start of the day this group covers (from `calendar.startOfDay`).
    let day: Date
    /// The day's expenses, ordered by `date` descending (latest time first).
    let expenses: [Expense]

    /// Sum of the day's expense amounts — the per-day total shown in the list header.
    var total: Decimal {
        expenses.reduce(Decimal(0)) { $0 + $1.amount }
    }
}

/// Group `expenses` by calendar day and sort:
/// - days descending (most recent first),
/// - within a day, by full `date` descending so the user-set time orders the rows.
func expenseDayGroups(_ expenses: [Expense], calendar: Calendar) -> [ExpenseDayGroup] {
    let grouped = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
    return grouped.keys.sorted(by: >).map { day in
        ExpenseDayGroup(
            day: day,
            expenses: (grouped[day] ?? []).sorted { $0.date > $1.date }
        )
    }
}
