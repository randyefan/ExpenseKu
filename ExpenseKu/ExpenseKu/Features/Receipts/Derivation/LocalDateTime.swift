//
//  LocalDateTime.swift
//  ExpenseKu
//
//  A date as printed on a receipt: no time zone, and a time only when the receipt has
//  one. A receipt date with no time keeps the form's clock time
//  (docs/prd/receipt-reading.md §4.4).
//

import Foundation

nonisolated struct LocalDateTime: Codable, Sendable, Hashable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int
    let hour: Int?
    let minute: Int?

    var description: String {
        let date = "\(year)-\(pad(month))-\(pad(day))"
        guard let hour, let minute else { return date }
        return "\(date) \(pad(hour)):\(pad(minute))"
    }

    func date(keepingClockOf clock: Date, calendar: Calendar) -> Date? {
        let kept = calendar.dateComponents([.hour, .minute], from: clock)
        let components = DateComponents(year: year, month: month, day: day,
                                        hour: hour ?? kept.hour, minute: minute ?? kept.minute)
        guard let date = calendar.date(from: components),
              calendar.component(.day, from: date) == day else { return nil }
        return date
    }

    private func pad(_ value: Int) -> String { value < 10 ? "0\(value)" : "\(value)" }
}
