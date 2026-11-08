//
//  MoneyCandidate.swift
//  ExpenseKu
//

import Foundation

nonisolated struct MoneyCandidate: IdentifiedCandidate, Hashable {
    let id: String
    let value: Decimal
    let spanID: String
}
