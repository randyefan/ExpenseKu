//
//  ReceiptModel.swift
//  ExpenseKu
//
//  The on-device language model that answers the extraction prompt. Gemma 4 E2B
//  through MLX when it is downloaded and can run; otherwise there is none and the rules
//  read the receipt (docs/prd/receipt-reading.md §4.9).
//

import Foundation

nonisolated protocol ReceiptModel: Sendable {
    func answer(_ prompt: String, image: Data) async throws -> String
}
