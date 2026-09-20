//
//  ExpenseKuSchema.swift
//  ExpenseKu
//
//  The versioned schema and its migration plan. V2 is the shape the app writes today:
//  Expense, Category, Person, Account with nullify delete rules (ADR-0001), plus the
//  cycle plan (docs/prd/payday-planning.md).
//
//  There is deliberately no V1 listed. A VersionedSchema's checksum comes from the
//  model types it lists *as compiled today*, and `Schema` pulls in every model
//  reachable through a relationship — so a V1 listing only the four 1.x models still
//  resolves to all nine entities and checksums identically to V2. Core Data rejects a
//  plan holding two versions with the same checksum ("Duplicate version checksums
//  detected"). A past version can therefore only appear here as frozen copies of the
//  old model types; since V1 → V2 was purely additive, it needs no stage at all and
//  SwiftData migrates 1.x stores to V2 on its own.
//
//  A future schema change adds a new VersionedSchema below. If it renames, retypes or
//  removes anything it needs a MigrationStage, and that stage's older version must be
//  frozen copies of the model types rather than the live ones. CloudKit rules apply to
//  every version regardless: new properties must be defaulted or optional, new
//  relationships must be optional, and uniqueness constraints are never allowed
//  (ADR-0002).
//

import Foundation
import SwiftData

/// The current store shape: the 1.x models plus the cycle plan — CyclePlan and its
/// three child kinds, CategoryGroup, `Expense.planItem`, `Expense.needsReview`,
/// `Category.group` and `Category.envelopes`.
enum ExpenseKuSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Expense.self, Category.self, Person.self, Account.self,
         CyclePlan.self, PlanItem.self, IncomeLine.self, TransferLine.self, CategoryGroup.self]
    }
}

enum ExpenseKuMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ExpenseKuSchemaV2.self]
    }

    static var stages: [MigrationStage] { [] }
}
