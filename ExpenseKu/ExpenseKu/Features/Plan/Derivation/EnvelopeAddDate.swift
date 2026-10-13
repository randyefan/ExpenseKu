//
//  EnvelopeAddDate.swift
//  ExpenseKu
//
//  The date ＋ on an envelope row gives the new expense (envelope-assignment.md §4.5).
//  It has to fall inside the cycle on screen: the envelope belongs to that cycle's
//  plan, and a date outside it would reset the assignment the moment the editor opened.
//

import Foundation

nonisolated enum EnvelopeAddDate {
    static func date(in cycle: PayCycle, now: Date, calendar: Calendar) -> Date {
        if cycle.contains(now) { return now }
        let day = now < cycle.start ? cycle.start : cycle.lastDay(calendar: calendar)
        let time = calendar.dateComponents([.hour, .minute], from: now)
        return calendar.date(bySettingHour: time.hour ?? 12, minute: time.minute ?? 0, second: 0, of: day) ?? day
    }
}
