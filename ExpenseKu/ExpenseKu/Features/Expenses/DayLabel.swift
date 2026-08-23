//
//  DayLabel.swift
//  ExpenseKu
//
//  How a day is named in the Expenses tab. `title` heads a day's section ("Today",
//  "Thu, 6 August"); `phrase` is the same day worded to sit inside a sentence, because
//  the title alone reads "No expenses on Today". Both depend on the current date, so
//  they belong somewhere tests can pin the calendar.
//

import Foundation

nonisolated enum DayLabel {
    static func title(_ day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.wide))
    }

    static func phrase(_ day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "today" }
        if calendar.isDateInYesterday(day) { return "yesterday" }
        return "on \(day.formatted(.dateTime.weekday(.abbreviated).day().month(.wide)))"
    }
}
