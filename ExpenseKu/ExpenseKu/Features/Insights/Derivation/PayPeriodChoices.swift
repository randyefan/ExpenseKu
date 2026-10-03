//
//  PayPeriodChoices.swift
//  ExpenseKu
//
//  Which cycles the Pay period menu offers, and which twelve Spend over Time draws
//  around the chosen one (docs/prd/insights-drill-in.md §5.2, §5.4).
//

import Foundation

nonisolated enum PayPeriodChoices {
    /// The current cycle back to the one holding the oldest expense, newest first. Empty
    /// cycles in between stay, so the list reads as an unbroken run of months.
    static func cycles(
        oldestExpense: Date?,
        now: Date = .now,
        payday: Int,
        calendar: Calendar = .current
    ) -> [PayCycle] {
        var cycle = PayCycle.containing(now, payday: payday, calendar: calendar)
        var cycles = [cycle]
        guard let oldestExpense else { return cycles }
        while cycle.start > oldestExpense {
            cycle = cycle.previous(payday: payday, calendar: calendar)
            cycles.append(cycle)
        }
        return cycles
    }

    /// The trend's window: the `count` cycles ending at the current one, slid back to end
    /// at `selected` only when the selected cycle falls before them.
    static func trendWindow(
        count: Int,
        selected: PayCycle?,
        now: Date = .now,
        payday: Int,
        calendar: Calendar = .current
    ) -> [PayCycle] {
        let window = SpendSummary.payPeriodWindow(cycles: count, payday: payday, now: now, calendar: calendar)
        guard let selected, let first = window.first, selected.start < first.start else { return window }
        return SpendSummary.payPeriodWindow(cycles: count, payday: payday, now: selected.start, calendar: calendar)
    }
}
