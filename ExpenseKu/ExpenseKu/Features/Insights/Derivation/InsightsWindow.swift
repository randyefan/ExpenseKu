//
//  InsightsWindow.swift
//  ExpenseKu
//
//  The span Insights and its drill-in read: a period preset and, for the Pay period
//  preset, which cycle (docs/prd/insights-drill-in.md §5). The leaderboard and Search
//  still use the bare DateRangeFilter, where "This pay period" can only mean the
//  current cycle.
//
//  A past cycle is its whole span. The current one keeps ADR-0003's spend-so-far end at
//  now, so nil stands for it rather than a stored cycle that would go stale at payday.
//

import Foundation

nonisolated struct InsightsWindow: Hashable {
    var preset: DateRangeFilter
    /// The pay period shown while `preset` is `.payPeriod`; nil is the one running now.
    var cycle: PayCycle?

    static func chipLabel(for preset: DateRangeFilter) -> String {
        preset == .payPeriod ? "Pay period" : preset.label
    }

    func payCycle(now: Date = .now, payday: Int, calendar: Calendar = .current) -> PayCycle {
        cycle ?? PayCycle.containing(now, payday: payday, calendar: calendar)
    }

    /// Takes a cycle from the menu, storing the current one as nil. False when nothing
    /// changed, so the caller leaves the plan filter alone.
    mutating func select(_ picked: PayCycle, now: Date = .now) -> Bool {
        let stored: PayCycle? = picked.contains(now) ? nil : picked
        guard stored != cycle else { return false }
        cycle = stored
        return true
    }

    func range(now: Date = .now, payday: Int, calendar: Calendar = .current) -> ClosedRange<Date>? {
        guard preset == .payPeriod, let cycle, !cycle.contains(now) else {
            return preset.range(now: now, calendar: calendar, payday: payday)
        }
        return cycle.start...cycle.end.addingTimeInterval(-0.001)
    }

    /// The window as a header names it: the cycle's title for a pay period.
    func label(now: Date = .now, payday: Int, calendar: Calendar = .current) -> String {
        guard preset == .payPeriod else { return preset.label }
        return payCycle(now: now, payday: payday, calendar: calendar).title(calendar: calendar)
    }

    /// The window worded to sit inside a sentence.
    func phrase(now: Date = .now, payday: Int, calendar: Calendar = .current) -> String {
        guard preset == .payPeriod else { return preset.phrase }
        return "in \(label(now: now, payday: payday, calendar: calendar))"
    }
}
