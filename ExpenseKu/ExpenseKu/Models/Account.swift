//
//  Account.swift
//  ExpenseKu
//
//  A reusable, owner-defined payment source an Expense was paid from — Cash, a
//  bank, an e-wallet. A label only: no balance, income, or transfers. Optional on
//  an Expense ("Unassigned" when absent). Mirrors Category/Person. See CONTEXT.md.
//

import Foundation
import SwiftData

@Model
final class Account {
    var name: String = ""
    var colorHex: String?

    // Deleting an Account nullifies each referencing expense's `account`
    // (rendered as "Unassigned") — never cascade-delete the expenses. ADR-0001.
    @Relationship(deleteRule: .nullify, inverse: \Expense.account)
    var expenses: [Expense]? = []

    init(name: String = "", colorHex: String? = nil) {
        self.name = name
        self.colorHex = colorHex
    }
}
