//
//  NamedEntity.swift
//  ExpenseKu
//
//  Shared de-duplication for the name-based entities (Category, Person).
//  CloudKit can't enforce unique constraints, so uniqueness is guarded here at
//  the point of creation — see ADR-0002.
//

import Foundation
import SwiftData

/// A SwiftData model identified to the owner by a free-text `name`.
protocol NamedEntity: PersistentModel {
    var name: String { get set }
}

extension Category: NamedEntity {}
extension Person: NamedEntity {}

enum NameKey {
    /// The comparison key for duplicate detection: trimmed + case-insensitive.
    static func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).localizedLowercase
    }
}

/// Returns an existing entity of type `T` whose name matches `name`
/// (trimmed, case-insensitive), or nil. `excluding` skips a specific entity so
/// renames don't collide with themselves.
func existingEntity<T: NamedEntity>(
    _ type: T.Type,
    matching name: String,
    in context: ModelContext,
    excluding: T? = nil
) -> T? {
    let key = NameKey.normalized(name)
    guard !key.isEmpty else { return nil }
    let all = (try? context.fetch(FetchDescriptor<T>())) ?? []
    return all.first {
        NameKey.normalized($0.name) == key && $0.persistentModelID != excluding?.persistentModelID
    }
}
