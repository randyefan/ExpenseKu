//
//  PersonExpensesRoute.swift
//  ExpenseKu
//
//  What a leaderboard row hands to the detail screen: identifiers for the person and
//  the filters that were active when it was tapped.
//
//  Identifiers rather than model instances, because a navigation path outlives the
//  objects put into it. The person can be deleted while this screen is still pushed —
//  by CloudKit sync from another device, or by `Person.reconcileMe` folding a duplicate
//  "Me" — and reading a deleted model is unsafe. Holding the identifier makes "it's
//  gone" a state the view can detect and render, instead of an unsafe access.
//

import Foundation
import SwiftData

struct PersonExpensesRoute: Hashable {
    let personID: PersistentIdentifier
    let categoryID: PersistentIdentifier?
    let accountID: PersistentIdentifier?
    let range: DateRangeFilter

    init(person: Person, category: Category?, account: Account?, range: DateRangeFilter) {
        self.personID = person.persistentModelID
        self.categoryID = category?.persistentModelID
        self.accountID = account?.persistentModelID
        self.range = range
    }

    func person(in context: ModelContext) -> Person? { context.existingModel(for: personID) }
    func category(in context: ModelContext) -> Category? { context.existingModel(for: categoryID) }
    func account(in context: ModelContext) -> Account? { context.existingModel(for: accountID) }
}
