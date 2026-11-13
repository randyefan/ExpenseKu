//
//  ReceiptReading.swift
//  ExpenseKu
//
//  What a receipt says: grounded facts and the model's short description of the visible
//  transaction (docs/prd/receipt-reading.md §1). Nil means the reading could not settle
//  that field, and the form keeps what it has (§4.4).
//

import Foundation

nonisolated struct ReceiptReading: Codable, Sendable, Hashable {
    var amount: Decimal?
    var fee: Decimal?
    var date: LocalDateTime?
    var bankBrandID: String?
    var counterparty: String?
    var categoryName: String?
    var expenseDescription: String?

    var isEmpty: Bool {
        amount == nil && date == nil && bankBrandID == nil && counterparty == nil && categoryName == nil
            && expenseDescription == nil
    }
}
