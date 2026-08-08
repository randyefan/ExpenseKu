//
//  Money.swift
//  ExpenseKu
//
//  Single implicit currency (IDR) for v1 — rupiah is written as whole numbers,
//  so we format with zero fraction digits. Multi-currency is a future migration.
//

import Foundation

extension Decimal {
    /// The amount formatted as Indonesian Rupiah, e.g. "Rp100,000".
    func formattedIDR() -> String {
        formatted(.currency(code: "IDR").precision(.fractionLength(0)))
    }

    /// Lossy Double for charting only (Swift Charts requires a Plottable value).
    /// Never use this in the money path — Decimal remains the source of truth.
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
