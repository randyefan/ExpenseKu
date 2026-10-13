//
//  EnvelopeAddDate.swift
//  ExpenseKu
//
//  The date ＋ on an envelope row gives the new expense (envelope-assignment.md §4.5,
//  §4.10.7). On a past cycle it has to fall inside that cycle: the envelope belongs to its
//  plan, and a later date would reset the assignment the moment the editor opened. On a
//  future cycle it is now — the money leaves today, and it counts there paid early.
//

import Foundation

nonisolated enum EnvelopeAddDate {
    static func date(in cycle: PayCycle, now: Date, calendar: Calendar) -> Date {
        if now < cycle.end { return now }
        let day = cycle.lastDay(calendar: calendar)
        let time = calendar.dateComponents([.hour, .minute], from: now)
        return calendar.date(bySettingHour: time.hour ?? 12, minute: time.minute ?? 0, second: 0, of: day) ?? day
    }
}
