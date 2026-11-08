//
//  ReceiptCandidates.swift
//  ExpenseKu
//
//  Every money value, date and bank on one receipt, in reading order.
//

import Foundation

nonisolated struct ReceiptCandidates: Sendable, Hashable {
    let money: [MoneyCandidate]
    let dates: [DateCandidate]
    let banks: [BankCandidate]
}
