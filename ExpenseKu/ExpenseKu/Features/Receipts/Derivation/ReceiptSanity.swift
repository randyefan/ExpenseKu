//
//  ReceiptSanity.swift
//  ExpenseKu
//
//  The last check before anything reaches the form. A reading is filled silently
//  (docs/prd/receipt-reading.md §4.4), so a value that cannot be right is dropped rather
//  than shown: an amount under Rp 1.000 (the "Rp 300 transfer" the owner named when the
//  feature began), and a fee that is zero or not smaller than the amount.
//

import Foundation

nonisolated enum ReceiptSanity {
    static let smallestAmount: Decimal = 1_000

    static func checked(_ reading: ReceiptReading) -> ReceiptReading {
        var reading = reading
        if let amount = reading.amount, amount < smallestAmount { reading.amount = nil }
        if let fee = reading.fee {
            if fee <= 0 || reading.amount.map({ fee >= $0 }) ?? true { reading.fee = nil }
        }
        if let counterparty = reading.counterparty?.trimmingCharacters(in: .whitespaces) {
            reading.counterparty = counterparty.contains(where: \.isLetter) ? counterparty : nil
        }
        if let description = reading.expenseDescription {
            let normalized = description.split(whereSeparator: \.isWhitespace).joined(separator: " ")
            reading.expenseDescription = normalized.count <= 160
                && normalized.contains(where: \.isLetter)
                && !["null", "none"].contains(normalized.lowercased()) ? normalized : nil
        }
        return reading
    }
}
