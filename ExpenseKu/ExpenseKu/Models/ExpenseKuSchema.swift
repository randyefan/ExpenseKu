//
//  ExpenseKuSchema.swift
//  ExpenseKu
//
//  The versioned schema and its migration plan. V1 is the shape shipped in 1.x:
//  Expense, Category, Person, Account with nullify delete rules (ADR-0001).
//
//  Every future schema change adds a *new* VersionedSchema and a MigrationStage here
//  rather than editing V1 — a store on an owner's device is always one of the versions
//  listed below, and V1 is what 1.x wrote. CloudKit rules still apply to every version:
//  new properties must be defaulted or optional, new relationships must be optional,
//  and uniqueness constraints are never allowed (ADR-0002).
//

import Foundation
import SwiftData

enum ExpenseKuSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Expense.self, Category.self, Person.self, Account.self]
    }
}

enum ExpenseKuMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ExpenseKuSchemaV1.self]
    }

    /// Empty while V1 is the only version: a stage describes a move *between* two
    /// versions, and there is nowhere to move from yet.
    static var stages: [MigrationStage] {
        []
    }
}
