//
//  PaidEarlyLabel.swift
//  ExpenseKu
//
//  How a paid-early expense names the cycle it counts in (envelope-assignment.md
//  §4.10.3, §4.10.5): "Nov" on the tag and the editor row, "November" for VoiceOver. It
//  is the month of that cycle's title, which is the month the cycle ends in, so 25 Oct –
//  24 Nov is "Nov". A year ahead or more, a month alone would name the wrong November.
//

import Foundation

nonisolated struct PaidEarlyLabel: Equatable {
    let short: String
    let long: String

    init(target: PayCycle, from cycle: PayCycle, calendar: Calendar) {
        let last = target.lastDay(calendar: calendar)
        let months = calendar.dateComponents([.month], from: cycle.lastDay(calendar: calendar), to: last).month ?? 0
        let showsYear = months >= 12
        short = last.formatted(showsYear ? .dateTime.month(.abbreviated).year() : .dateTime.month(.abbreviated))
        long = last.formatted(showsYear ? .dateTime.month(.wide).year() : .dateTime.month(.wide))
    }
}
