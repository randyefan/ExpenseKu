//
//  Money.swift
//  ExpenseKu
//
//  Single implicit currency (IDR) for v1 — rupiah is written as whole numbers,
//  so we format with zero fraction digits. Multi-currency is a future migration.
//

import Foundation

nonisolated extension Decimal {
    /// The amount formatted as Indonesian Rupiah, e.g. "Rp100,000".
    func formattedIDR() -> String {
        formatted(.currency(code: "IDR").precision(.fractionLength(0)))
    }

    /// A short form for tight spots such as a chart callout, e.g. "220RB" or
    /// "11,3JT". One optional decimal, so millions keep a useful digit while
    /// round thousands stay clean, and no currency mark: a bar label has one
    /// slot's width to live in, and every amount in the app is rupiah.
    /// Locale decides the suffix, so this stays correct outside id-ID.
    func compactAmount() -> String {
        formatted(
            .number
                .precision(.fractionLength(0...1))
                .rounded(rule: .toNearestOrAwayFromZero)
                .notation(.compactName)
        )
    }

    /// Lossy Double for charting only (Swift Charts requires a Plottable value).
    /// Never use this in the money path — Decimal remains the source of truth.
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
