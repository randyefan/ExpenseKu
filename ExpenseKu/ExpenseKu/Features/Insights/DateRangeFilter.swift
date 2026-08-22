//
//  DateRangeFilter.swift
//  ExpenseKu
//
//  Preset time windows for the Insights filters. Produces a ClosedRange<Date>?
//  (nil = all time) that the pure analytics layer consumes.
//

import Foundation

nonisolated enum DateRangeFilter: String, CaseIterable, Identifiable {
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
            // The pay period's start is the cycle-boundary math owned by PayCycle —
            // one clamp implementation shared with the home screen (ADR-0004). This
            // preset keeps its "spend-so-far" end at `now`.
            return PayCycle.containing(now, payday: payday, calendar: calendar).start...now
        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return start...now
        }
    }
}
