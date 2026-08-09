//
//  DateRangeFilter.swift
//  ExpenseKu
//
//  Preset time windows for the Insights filters. Produces a ClosedRange<Date>?
//  (nil = all time) that the pure analytics layer consumes.
//

import Foundation

enum DateRangeFilter: String, CaseIterable, Identifiable {
    case allTime
    case last30Days
    case thisMonth
    case payPeriod
    case thisYear

    var id: String { rawValue }

    var label: String {
        switch self {
        case .allTime: "All time"
        case .last30Days: "Last 30 days"
        case .thisMonth: "This month"
        case .payPeriod: "This pay period"
        case .thisYear: "This year"
        }
    }

    /// The window as a closed date range, or nil for "all time".
    ///
    /// - Parameter payday: day-of-month the pay period is anchored to (1...31),
    ///   used only by `.payPeriod`; every other case ignores it. Defaults to 1,
    ///   which makes `.payPeriod` identical to `.thisMonth`.
    func range(now: Date = .now, calendar: Calendar = .current, payday: Int = 1) -> ClosedRange<Date>? {
        switch self {
        case .allTime:
            return nil
        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return start...now
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return start...now
        case .payPeriod:
            return payPeriodStart(now: now, calendar: calendar, payday: payday)...now
        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return start...now
        }
    }

    /// Start of the pay period containing `now`: the most recent payday on-or-before
    /// `now`. The payday is clamped to the last valid day of a short month (a 31 anchor
    /// lands on Feb 28/29), and normalized to the start of that day.
    private func payPeriodStart(now: Date, calendar: Calendar, payday: Int) -> Date {
        let day = max(1, min(31, payday))

        func paydayDate(inMonthContaining reference: Date) -> Date {
            var comps = calendar.dateComponents([.year, .month], from: reference)
            let monthStart = calendar.date(from: comps) ?? reference
            let lastDay = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 28
            comps.day = min(day, lastDay)
            let date = calendar.date(from: comps) ?? reference
            return calendar.startOfDay(for: date)
        }

        let thisMonthsPayday = paydayDate(inMonthContaining: now)
        if thisMonthsPayday <= now {
            return thisMonthsPayday
        }
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        return paydayDate(inMonthContaining: previousMonth)
    }
}
