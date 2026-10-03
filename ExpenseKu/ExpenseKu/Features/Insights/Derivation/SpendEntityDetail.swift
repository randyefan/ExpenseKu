//
//  SpendEntityDetail.swift
//  ExpenseKu
//
//  Every figure on a category or account drill-in (docs/prd/insights-drill-in.md §4,
//  §6.3), from one pass over the window's expenses.
//
//  Three filters apply in different places, and that is the whole point of keeping
//  them here: the split card shows the subject (after narrowing) in both halves, the
//  breakdown shows the subject's half in every bucket (so a narrowed-away bucket keeps
//  its figure), and the header and list show all three applied.
//

import Foundation

nonisolated struct SpendEntityDetail {
    /// Subject, narrowing and plan filter applied; input order kept.
    let listed: [Expense]
    let total: Decimal
    /// Nil when the subject has nothing here: a share of nothing is undefined, not 0%.
    let share: Double?
    let split: SpendingSplit
    let breakdown: [SpendBreakdownRow]

    init(
        expenses: [Expense],
        subject: SpendSubject,
        narrowing: SpendSubject?,
        dateRange: ClosedRange<Date>?,
        planFilter: PlanFilter?,
        origins: PlanOrigins
    ) {
        let window = expenses.filter { dateRange?.contains($0.date) ?? true }
        let windowHalf = planFilter.map { origins.expenses(window, matching: $0) } ?? window
        let subjectHalf = windowHalf.filter(subject.matches)

        let narrowed = window.filter { subject.matches($0) && (narrowing?.matches($0) ?? true) }
        listed = narrowing.map { focus in subjectHalf.filter(focus.matches) } ?? subjectHalf
        total = listed.reduce(0) { $0 + $1.amount }
        split = origins.split(narrowed)

        let windowHalfTotal = windowHalf.reduce(Decimal(0)) { $0 + $1.amount }
        share = total > 0 && windowHalfTotal > 0
            ? NSDecimalNumber(decimal: total / windowHalfTotal).doubleValue
            : nil

        breakdown = subject.isCategory
            ? SpendSummary.byAccount(from: subjectHalf).map(SpendBreakdownRow.init)
            : SpendSummary.byCategory(from: subjectHalf).map(SpendBreakdownRow.init)
    }

    static func emptyTitle(planFilter: PlanFilter?) -> String {
        planFilter?.emptyCycleTitle ?? "Nothing in This Window"
    }

    static func emptyMessage(name: String, planFilter: PlanFilter?, windowPhrase: String) -> String {
        guard let planFilter else { return "\(name) has no expenses \(windowPhrase)." }
        return "\(name) has no expenses \(planFilter.phrase) \(windowPhrase)."
    }
}
