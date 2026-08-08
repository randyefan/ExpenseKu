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
    case thisYear

    var id: String { rawValue }

    var label: String {
        switch self {
        case .allTime: "All time"
        case .last30Days: "Last 30 days"
        case .thisMonth: "This month"
        case .thisYear: "This year"
        }
    }

    /// The window as a closed date range, or nil for "all time".
    func range(now: Date = .now, calendar: Calendar = .current) -> ClosedRange<Date>? {
        switch self {
        case .allTime:
            return nil
        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return start...now
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return start...now
        case .thisYear:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return start...now
        }
    }
}
