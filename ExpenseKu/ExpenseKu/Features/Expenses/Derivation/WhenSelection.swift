//
//  WhenSelection.swift
//  ExpenseKu
//
//  Which date chip is lit (docs/prd/quick-entry-form.md §4.1). A chip the owner tapped
//  stays lit while the date is still the one it set; otherwise the date is matched
//  against now to the minute, and a date no chip names becomes a chip of its own.
//

import Foundation

nonisolated enum WhenSelection: Equatable, Sendable {
    case shortcut(WhenShortcut)
    /// A date no chip names: picked by hand, or an edited expense's stored date.
    case custom(Date)

    static func resolve(date: Date, tap: WhenTap?, now: Date, calendar: Calendar) -> WhenSelection {
        if let tap, tap.date == date {
            return .shortcut(tap.shortcut)
        }
        let match = WhenShortcut.allCases.first {
            calendar.isDate($0.date(from: now, calendar: calendar), equalTo: date, toGranularity: .minute)
        }
        return match.map(WhenSelection.shortcut) ?? .custom(date)
    }
}
