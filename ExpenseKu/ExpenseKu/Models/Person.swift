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

    // The single protected "Me" (the owner). Exactly one Person carries this flag;
    // it is auto-selected on a new expense (but can be unselected), pinned to the
    // top of pickers, can't be renamed/deleted, and is hidden from the People
    // leaderboard (which ranks *companions*, not the owner). Defaulted for CloudKit.
    var isMe: Bool = false

    // Deleting a Person removes them from each expense's `people` — the expenses
    // themselves survive. ADR-0001.
    @Relationship(deleteRule: .nullify, inverse: \Expense.people)
    var expenses: [Expense]? = []

    init(name: String = "", isMe: Bool = false) {
        self.name = name
        self.isMe = isMe
    }
}

extension Person {
    /// The default display name for the protected owner entry.
    static let meName = "Me"

    /// Guarantees exactly one protected "Me" exists. Called at app launch; creates
    /// it on first run and is a no-op thereafter. Idempotent and safe to call often.
    @MainActor
    static func ensureMe(in context: ModelContext) {
        var descriptor = FetchDescriptor<Person>(predicate: #Predicate { $0.isMe })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor), !existing.isEmpty { return }
        context.insert(Person(name: meName, isMe: true))
    }
}
