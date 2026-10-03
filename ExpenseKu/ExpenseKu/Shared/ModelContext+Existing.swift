//
//  ModelContext+Existing.swift
//  ExpenseKu
//
//  Resolving a stored identifier back to a live model, for navigation routes that hold
//  identifiers because a path outlives the objects put into it.
//

import Foundation
import SwiftData

extension ModelContext {
    /// Nil when the identifier is absent or its object has since been deleted.
    ///
    /// Deliberately not `ModelContext.model(for:)`: that one *crashes* on a deleted
    /// identifier rather than returning nil, which is the exact case these routes exist
    /// to survive. `registeredModel(for:)` answers from memory and returns nil once the
    /// object is gone; the fetch covers a live object this context has not registered.
    func existingModel<T: PersistentModel>(for id: PersistentIdentifier?) -> T? {
        guard let id else { return nil }
        if let registered: T = registeredModel(for: id) {
            return registered.isDeleted ? nil : registered
        }
        var descriptor = FetchDescriptor<T>(predicate: #Predicate { $0.persistentModelID == id })
        descriptor.fetchLimit = 1
        return try? fetch(descriptor).first
    }
}
