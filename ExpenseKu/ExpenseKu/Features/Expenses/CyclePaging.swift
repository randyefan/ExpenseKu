//
//  CyclePaging.swift
//  ExpenseKu
//
//  When the ‹ › cycle arrows are enabled. Pure boundary checks, extracted from
//  ExpensesView so the off-by-one cases are covered by tests rather than by
//  inspection.
//
//  Forward used to stop at the present cycle, so paging never landed on an empty
//  future one (Q7). The cycle plan reverses that: the next cycle is precisely where
//  planning happens (PRD §7.1). It opens up in **every** lens, not only in Plan — an
//  arrow that enables and disables depending on which toggle is selected reads as a
//  bug, and List and Month already have an empty state that says the right thing.
//
//  Back learned about plans at the same time. It used to key off the oldest Expense
//  alone, which would have made a cycle holding only a plan unreachable — and a plan
//  built a cycle ahead is exactly that until its cycle starts.
//

import Foundation

nonisolated enum CyclePaging {
    /// Enabled while anything older than this cycle exists, whether that is an expense
    /// or a plan.
    static func canGoBack(from cycle: PayCycle, oldestExpense: Date?, oldestPlanStart: Date?) -> Bool {
        guard let oldest = [oldestExpense, oldestPlanStart].compactMap({ $0 }).min() else {
            return false
        }
        return oldest < cycle.start
    }

    /// Always enabled. Kept as a function rather than inlined as `true` so a future
    /// bound — if one is ever wanted — has one place to live, and so the call site
    /// keeps reading as a question about paging rather than a bare constant.
    static func canGoForward(from cycle: PayCycle) -> Bool {
        true
    }
}
