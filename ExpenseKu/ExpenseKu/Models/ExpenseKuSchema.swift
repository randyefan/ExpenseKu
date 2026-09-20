//
//  ExpenseKuSchema.swift
//  ExpenseKu
//
//  The versioned schema and its migration plan. V1 is the shape shipped in 1.x:
//  Expense, Category, Person, Account with nullify delete rules (ADR-0001). V2 adds
//  the cycle plan (docs/prd/payday-planning.md).
//
//  Every future schema change adds a *new* VersionedSchema and a MigrationStage here
//  rather than editing an existing one — a store on an owner's device is always one of
//  the versions listed below, and V1 is what 1.x wrote. CloudKit rules still apply to
//  every version: new properties must be defaulted or optional, new relationships must
//  be optional, and uniqueness constraints are never allowed (ADR-0002).
//

import Foundation
import SwiftData

enum ExpenseKuSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Expense.self, Category.self, Person.self, Account.self]
    }
}

/// Adds the cycle plan: CyclePlan and its three child kinds, plus CategoryGroup.
/// Expense gains `planItem` and `needsReview`; Category gains `group` and `envelopes`.
enum ExpenseKuSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Expense.self, Category.self, Person.self, Account.self,
         CyclePlan.self, PlanItem.self, IncomeLine.self, TransferLine.self, CategoryGroup.self]
    }
}

enum ExpenseKuMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ExpenseKuSchemaV1.self, ExpenseKuSchemaV2.self]
    }

    /// V1 → V2 is lightweight: every change is an addition, and every added property
    /// is optional or defaulted. Nothing is renamed, retyped or removed, so SwiftData
    /// needs no custom willMigrate/didMigrate to fill anything in.
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: ExpenseKuSchemaV1.self, toVersion: ExpenseKuSchemaV2.self)]
    }
}
