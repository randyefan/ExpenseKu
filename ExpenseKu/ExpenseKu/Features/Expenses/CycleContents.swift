//
//  CycleContents.swift
//  ExpenseKu
//
//  Everything the Expenses tab derives from one pay cycle: the cycle's own expenses,
//  their total, and the day grouping both lenses read. Computed once per body pass
//  rather than re-derived by each caller, and pure so it can be unit-tested without a
//  ModelContainer — the same shape as the SpendSummary / PeopleLeaderboard layers.
//

import Foundation

nonisolated struct CycleContents {
    let expenses: [Expense]
    let total: Decimal
    let dayGroups: [ExpenseDayGroup]

    init(cycle: PayCycle, allExpenses: [Expense], calendar: Calendar) {
        let inCycle = allExpenses.filter { cycle.contains($0.date) }
        self.expenses = inCycle
        self.total = inCycle.reduce(Decimal(0)) { $0 + $1.amount }
        self.dayGroups = expenseDayGroups(inCycle, calendar: calendar)
    }

    var isEmpty: Bool { expenses.isEmpty }

    func group(for day: Date) -> ExpenseDayGroup? {
        dayGroups.first { $0.day == day }
    }
}
