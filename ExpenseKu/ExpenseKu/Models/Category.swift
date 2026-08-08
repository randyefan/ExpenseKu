//
//  Category.swift
//  ExpenseKu
//
//  A reusable, owner-defined label for *what kind* of spend an Expense is
//  (e.g. "Makan"). An Expense has exactly one, required at entry.
//

import Foundation
import SwiftData

@Model
final class Category {
    var name: String = ""
    var colorHex: String?

    // Deleting a Category nullifies each referencing expense's `category`
    // (rendered as "Uncategorized") — never cascade-delete the expenses. ADR-0001.
    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense]? = []

    init(name: String = "", colorHex: String? = nil) {
        self.name = name
        self.colorHex = colorHex
    }
}
