//
//  WhenShortcut.swift
//  ExpenseKu
//
//  The date chips over the expense editor (docs/prd/quick-entry-form.md §4.1). Each one
//  counts back from the moment it is tapped, never from when the form opened.
//

import Foundation

nonisolated enum WhenShortcut: CaseIterable, Hashable, Sendable {
    case now
    case oneHourAgo
    case threeHoursAgo
    case yesterday

    var title: String {
        switch self {
        case .now: AppLocalization.string(.now)
        case .oneHourAgo: AppLocalization.string(.oneHourAgo)
        case .threeHoursAgo: AppLocalization.string(.threeHoursAgo)
        case .yesterday: AppLocalization.string(.yesterday)
        }
    }

    /// Yesterday keeps the clock time, so 20.15 today is 20.15 yesterday.
    func date(from now: Date, calendar: Calendar) -> Date {
        let back: (Calendar.Component, Int)? = switch self {
        case .now: nil
        case .oneHourAgo: (.hour, -1)
        case .threeHoursAgo: (.hour, -3)
        case .yesterday: (.day, -1)
        }
        guard let (component, value) = back else { return now }
        return calendar.date(byAdding: component, value: value, to: now) ?? now
    }
}
