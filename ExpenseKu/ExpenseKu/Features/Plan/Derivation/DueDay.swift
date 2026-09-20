//
//  DueDay.swift
//  ExpenseKu
//
//  Resolving a PlanItem's day-of-month to a real date inside a cycle, and the badge
//  it renders as (PRD §7.4).
//
//  A due day is a day-of-month rather than a date so carry-over reproduces it without
//  re-entry. Two things about that are easy to get wrong by hand, which is why this
//  is a tested pure type and not a few lines in a view:
//
//  A cycle spans two calendar months. With payday 25, a due day of 20 belongs to the
//  cycle's *second* month; with payday 1 it belongs to the first. So both candidates
//  are built and the one the cycle actually contains wins.
//
//  Days 29–31 must clamp to the end of a short month. That clamp already exists, in
//  PayCycle.paydayDate(inMonthContaining:payday:calendar:) — the single source of
//  truth the Payday anchor itself uses. Reimplementing it here would be a second
//  answer to the same question, free to drift.
//

import Foundation

nonisolated enum DueDay {
    /// The valid range for a day-of-month, matching `Payday.range`.
    static let range = 1...31

    /// The concrete date `day` resolves to inside `cycle`, or nil when neither of the
    /// cycle's two months places it in range — which happens legitimately: with payday
    /// 15, a cycle running 15 Jan → 15 Feb contains no 14th of January.
    static func date(day: Int, in cycle: PayCycle, calendar: Calendar) -> Date? {
        let clamped = max(range.lowerBound, min(range.upperBound, day))
        let candidates = [cycle.start, cycle.lastDay(calendar: calendar)].map {
            PayCycle.paydayDate(inMonthContaining: $0, payday: clamped, calendar: calendar)
        }
        return candidates.first { cycle.contains($0) }
    }

    /// How the badge reads. Absolute by default — "Due 25" is what carry-over stores
    /// and what the owner recognises. Relative only when `today` is inside the cycle
    /// and the date is within three days, because a countdown in a cycle that has not
    /// started is meaningless.
    static func label(day: Int, in cycle: PayCycle, today: Date, calendar: Calendar) -> DueLabel {
        let absolute = DueLabel(text: "Due \(max(range.lowerBound, min(range.upperBound, day)))", isSoon: false)
        guard cycle.contains(today), let due = date(day: day, in: cycle, calendar: calendar) else {
            return absolute
        }
        let startOfToday = calendar.startOfDay(for: today)
        guard let days = calendar.dateComponents([.day], from: startOfToday, to: due).day,
              (0...3).contains(days) else {
            return absolute
        }
        if days == 0 { return DueLabel(text: "due today", isSoon: true) }
        return DueLabel(text: "due in " + PlanCopy.counted(days, "day"), isSoon: true)
    }
}

/// What a `PlanChip · Due` renders. `isSoon` swaps it to the accent variant.
nonisolated struct DueLabel: Equatable {
    let text: String
    let isSoon: Bool
}
