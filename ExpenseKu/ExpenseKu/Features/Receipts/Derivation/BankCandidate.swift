//
//  BankCandidate.swift
//  ExpenseKu
//
//  A bank named on a receipt, as its bank-logo catalog `brandID` (ADR-0012).
//

import Foundation

nonisolated struct BankCandidate: IdentifiedCandidate, Hashable {
    let id: String
    let brandID: String
    let spanID: String
}
