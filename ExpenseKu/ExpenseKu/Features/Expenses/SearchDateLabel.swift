//
//  SearchDateLabel.swift
//  ExpenseKu
//
//  How a date is named on a search result row. Results span years, so each row
//  carries its own date and picks up a year exactly when it is not from the
//  current one. Deliberately not `DayLabel`: no "Today"/"Yesterday" here, because
//  "Today" sitting next to "3 Mar 25" in one scrolling list reads as two
//  different kinds of thing. `now` is injectable so tests can pin the boundary.
//

import Foundation

nonisolated enum SearchDateLabel {
    static func text(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        return sameYear
            ? date.formatted(.dateTime.day().month(.abbreviated))
            : date.formatted(.dateTime.day().month(.abbreviated).year(.twoDigits))
    }
}
