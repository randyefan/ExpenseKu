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

    func person(in context: ModelContext) -> Person? { resolve(personID, in: context) }
    func category(in context: ModelContext) -> Category? { resolve(categoryID, in: context) }
    func account(in context: ModelContext) -> Account? { resolve(accountID, in: context) }

    /// Nil when the identifier is absent or its object has since been deleted.
    ///
    /// Deliberately not `ModelContext.model(for:)`: that one *crashes* on a deleted
    /// identifier rather than returning nil, which is the exact case this route exists
    /// to survive. `registeredModel(for:)` answers from memory and returns nil once the
    /// object is gone; the fetch covers a live object this context has not registered.
    private func resolve<T: PersistentModel>(_ id: PersistentIdentifier?, in context: ModelContext) -> T? {
        guard let id else { return nil }
        if let registered: T = context.registeredModel(for: id) {
            return registered.isDeleted ? nil : registered
        }
        var descriptor = FetchDescriptor<T>(predicate: #Predicate { $0.persistentModelID == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
