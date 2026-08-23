//
//  PayCycle.swift
//  ExpenseKu
//
//  A single pay cycle: the half-open interval [start, end) anchored to a monthly
//  start day (the owner's "Monthly Start Date" / payday). This is the home screen's
//  primary lens — the pure boundary math kept out of the views so it stays
//  unit-testable. It is also the single source of truth for the payday clamp that
//  the Insights "This pay period" preset reuses (ADR-0004 supersedes ADR-0003's
//  analytics-only scope). Monthly cycle only; the anchor is a day-of-month integer.
//

import Foundation

nonisolated struct PayCycle: Equatable, Identifiable {
    /// Inclusive lower bound, normalized to the start of the day.
    let start: Date
    /// Exclusive upper bound — the start of the next cycle. A cycle therefore
    /// covers `start ..< end`; the last *included* day is `end - 1 day`.
    let end: Date

    var id: Date { start }

    /// Whether `date` falls in this cycle (`start <= date < end`).
    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }

    // MARK: - Construction

    /// The cycle containing `date`, anchored to `payday` (1...31). In a month too
    /// short for the anchor, the boundary clamps to the last valid day, so with a
    /// 31 anchor a cycle can run Jan 31 → Feb 28 and the next Feb 28 → Mar 31.
    static func containing(_ date: Date, payday: Int, calendar: Calendar = .current) -> PayCycle {
        let start = cycleStart(onOrBefore: date, payday: payday, calendar: calendar)
        // The next boundary is the anchored payday of the following month. Adding a
        // month to a clamped short-month start (e.g. Feb 28) already lands Calendar
        // in the right month; re-clamping fixes the day-of-month.
        let nextMonthRef = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        let end = paydayDate(inMonthContaining: nextMonthRef, payday: payday, calendar: calendar)
        return PayCycle(start: start, end: end)
    }

    /// The cycle immediately before this one.
    func previous(payday: Int, calendar: Calendar = .current) -> PayCycle {
        let dayBeforeStart = calendar.date(byAdding: .day, value: -1, to: start) ?? start
        return PayCycle.containing(dayBeforeStart, payday: payday, calendar: calendar)
    }

    /// The cycle immediately after this one.
    func next(payday: Int, calendar: Calendar = .current) -> PayCycle {
        PayCycle.containing(end, payday: payday, calendar: calendar)
    }

    // MARK: - Display

    /// The last day the cycle includes (`end - 1 day`), at the start of that day.
    func lastDay(calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: end) ?? end)
    }

    /// The cycle's title, named by the month it *ends* in (Q4): the cycle
    /// 25 Jul → 24 Aug is titled "August 2026".
    func title(calendar: Calendar = .current) -> String {
        lastDay(calendar: calendar).formatted(.dateTime.month(.wide).year())
    }

    /// The closed span as "25/07/2026 ~ 24/08/2026" (start → last included day).
    func rangeText(calendar: Calendar = .current) -> String {
        let f = Self.rangeFormatter(calendar: calendar)
        return "\(f.string(from: start)) ~ \(f.string(from: lastDay(calendar: calendar)))"
    }

    // MARK: - Boundary math (the single clamp source of truth)

    /// The anchored payday within the month containing `reference`, clamped to the
    /// month's last day when the anchor overflows (31 → Feb 28/29), at start of day.
    static func paydayDate(inMonthContaining reference: Date, payday: Int, calendar: Calendar) -> Date {
        let day = max(1, min(31, payday))
        var comps = calendar.dateComponents([.year, .month], from: reference)
        let monthStart = calendar.date(from: comps) ?? reference
        let lastDay = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 28
        comps.day = min(day, lastDay)
        let date = calendar.date(from: comps) ?? reference
        return calendar.startOfDay(for: date)
    }

    /// The most recent cycle start on-or-before `date`.
    private static func cycleStart(onOrBefore date: Date, payday: Int, calendar: Calendar) -> Date {
        let thisMonthsPayday = paydayDate(inMonthContaining: date, payday: payday, calendar: calendar)
        if thisMonthsPayday <= date {
            return thisMonthsPayday
        }
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: date) ?? date
        return paydayDate(inMonthContaining: previousMonth, payday: payday, calendar: calendar)
    }

    private static func rangeFormatter(calendar: Calendar) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "dd/MM/yyyy"
        return f
    }
}
