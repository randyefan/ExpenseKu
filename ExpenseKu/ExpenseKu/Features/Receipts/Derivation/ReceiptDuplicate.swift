//
//  ReceiptDuplicate.swift
//  ExpenseKu
//
//  "Looks already logged" (docs/prd/receipt-reading.md §4.6): an expense with the same
//  amount, or the amount plus its fee, on the receipt's calendar day. A reading with no
//  amount or no date is never checked.
//

import Foundation

nonisolated enum ReceiptDuplicate {
    struct Logged<ID: Hashable> {
        let id: ID
        let amount: Decimal
        let date: Date
    }

    static func match<ID: Hashable>(_ reading: ReceiptReading, in logged: [Logged<ID>],
                                    calendar: Calendar) -> ID? {
        guard let amount = reading.amount, let day = reading.date else { return nil }
        let amounts: Set<Decimal> = [amount, amount + (reading.fee ?? 0)]
        return logged.first { expense in
            let parts = calendar.dateComponents([.year, .month, .day], from: expense.date)
            return amounts.contains(expense.amount)
                && parts.year == day.year && parts.month == day.month && parts.day == day.day
        }?.id
    }
}
