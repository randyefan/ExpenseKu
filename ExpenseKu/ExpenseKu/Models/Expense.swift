//
//  Expense.swift
//  ExpenseKu
//
//  A single record of money the owner spent. Amount + when + one Category +
//  zero-or-more People (companions). See CONTEXT.md for the ubiquitous language.
//

import Foundation
import SwiftData

@Model
final class Expense {
    // All stored properties are defaulted for CloudKit mirroring (no non-optional,
    // no-default attributes allowed). Money is Decimal, never Double.
    var amount: Decimal = 0
    var date: Date = Date.now
    var note: String = ""

    // Relationships are optional per CloudKit. `category` is required by the UI at
    // entry (see design.md §5); it can only become nil later via category deletion,
    // which the UI renders as "Uncategorized" (ADR-0001). Inverses live on the
    // Category/Person side.
    var category: Category?
    var people: [Person]? = []

    init(
        amount: Decimal = 0,
        date: Date = .now,
        note: String = "",
        category: Category? = nil,
        people: [Person] = []
    ) {
        self.amount = amount
        self.date = date
        self.note = note
        self.category = category
        self.people = people
    }
}
