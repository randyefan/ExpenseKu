//
//  Person.swift
//  ExpenseKu
//
//  A reusable companion the owner was *with* when spending — not a beneficiary,
//  no bill-splitting. Many-to-many with Expense; powers the People leaderboard.
//

import Foundation
import SwiftData

@Model
final class Person {
    var name: String = ""

    // Deleting a Person removes them from each expense's `people` — the expenses
    // themselves survive. ADR-0001.
    @Relationship(deleteRule: .nullify, inverse: \Expense.people)
    var expenses: [Expense]? = []

    init(name: String = "") {
        self.name = name
    }
}
