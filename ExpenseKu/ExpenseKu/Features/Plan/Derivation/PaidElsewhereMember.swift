//
//  PaidElsewhereMember.swift
//  ExpenseKu
//
//  One paid-elsewhere expense, as its Account's row and sheet need it
//  (docs/prd/paid-elsewhere.md §4.5). A value, so the derivations are testable without
//  the expenses, and a write still finds its expense by `id`.
//

import Foundation
import SwiftData

nonisolated struct PaidElsewhereMember: Identifiable, Equatable {
    let id: PersistentIdentifier
    let name: String
    let note: String
    let categoryName: String
    let date: Date
    let amount: Decimal
    let isMoved: Bool
    let dayLabel: String

    init(expense: Expense, calendar: Calendar = .current) {
        id = expense.persistentModelID
        categoryName = expense.category?.name ?? LookBackCopy.uncategorized
        note = expense.note
        name = expense.note.isEmpty ? categoryName : expense.note
        date = expense.date
        amount = expense.amount
        isMoved = expense.isMovedFromEnvelope
        var style = Date.FormatStyle.dateTime.day().month(.abbreviated)
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        style.locale = AppLocalization.locale
        dayLabel = expense.date.formatted(style)
    }

    /// "28 Oct · Sewa". No Account: the sheet's title already names it.
    var caption: String { "\(dayLabel) · \(categoryName)" }

    /// The order a card statement lists them: date ↑, then amount ↓, then note (§4.5.1).
    static func precedes(_ a: PaidElsewhereMember, _ b: PaidElsewhereMember) -> Bool {
        if a.date != b.date { return a.date < b.date }
        if a.amount != b.amount { return a.amount > b.amount }
        return a.note.localizedStandardCompare(b.note) == .orderedAscending
    }
}
