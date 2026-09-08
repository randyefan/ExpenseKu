//
//  DayLabel.swift
//  ExpenseKu
//
//  How a day is named in the Expenses tab. `title` heads a day's section ("Today",
//  "Thu, 6 August"); `phrase` is the same day worded to sit inside a sentence, because
//  the title alone reads "No expenses on Today". `spanningTitle` is `title` for a list
//  that crosses years, where an unqualified "Thu, 18 December" is ambiguous. All three
//  depend on the current date, so they belong somewhere tests can pin the calendar.
//

import Foundation

nonisolated enum DayLabel {
    static func title(_ day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.wide))
    }

    /// `title`, plus the year on a day outside the current one — for a list that
    /// spans years, such as a companion's all-time drill-down.
    static func spanningTitle(_ day: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let title = title(day, calendar: calendar)
        guard calendar.component(.year, from: day) != calendar.component(.year, from: now),
              !calendar.isDateInToday(day), !calendar.isDateInYesterday(day) else {
            return title
        }
        return "\(title) \(day.formatted(.dateTime.year()))"
    }

    static func phrase(_ day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "today" }
        if calendar.isDateInYesterday(day) { return "yesterday" }
        return "on \(day.formatted(.dateTime.weekday(.abbreviated).day().month(.wide)))"
    }
}
