//
//  TextSpan.swift
//  ExpenseKu
//
//  One piece of text Vision read off a receipt, with the id the model answers with
//  (docs/prd/receipt-reading.md §1).
//

import Foundation

nonisolated struct TextSpan: Codable, Sendable, Hashable {
    let id: String
    let text: String
}
