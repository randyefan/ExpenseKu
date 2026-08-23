//
//  CyclePaging.swift
//  ExpenseKu
//
//  When the ‹ › cycle arrows are enabled. Back stops once there is no older data to
//  reach; forward stops at the present cycle, so paging never lands on an empty future
//  one (Q7). Pure boundary checks, extracted from ExpensesView so the off-by-one cases
//  are covered by tests rather than by inspection.
//

import Foundation

nonisolated enum CyclePaging {
    static func canGoBack(from cycle: PayCycle, oldestExpense: Date?) -> Bool {
        guard let oldestExpense else { return false }
        return oldestExpense < cycle.start
    }

    static func canGoForward(from cycle: PayCycle, now: Date) -> Bool {
        cycle.end <= now
    }
}
