//
//  ReadAheadProgress.swift
//  ExpenseKu
//
//  The receipt a foreground pass has in hand, of those it reads this time
//  (docs/prd/receipt-reading.md §4.11).
//

import Foundation

nonisolated struct ReadAheadProgress: Sendable, Hashable {
    let position: Int
    let total: Int
}
