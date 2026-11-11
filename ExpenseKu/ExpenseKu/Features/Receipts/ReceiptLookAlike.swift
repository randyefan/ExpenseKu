//
//  ReceiptLookAlike.swift
//  ExpenseKu
//
//  A reading that matches an expense already logged, held while "Looks already logged"
//  asks what to do (docs/prd/receipt-reading.md §4.6, frame AG6).
//

import Foundation

struct ReceiptLookAlike {
    let reading: ReceiptReading
    let source: ReceiptReadingSource?
    let image: Data
    let expense: Expense

    var description: String {
        var parts = [expense.amount.formattedIDR(),
                     expense.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(AppLocalization.locale))]
        if !expense.note.isEmpty { parts.append(expense.note) }
        return AppLocalization.string(.receiptAlreadyLogged(parts.joined(separator: " · ")))
    }
}
