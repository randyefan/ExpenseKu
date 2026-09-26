//
//  ExpenseKuSchema.swift
//  ExpenseKu
//
//  The versioned schema and its migration plan. V3 is the shape the app writes today:
//  Expense, Category, Person, Account with nullify delete rules (ADR-0001), the cycle
//  plan (docs/prd/payday-planning.md), and `PlanItem.isFunded` (§7.6).
//
//  There is deliberately no V1 or V2 listed. A VersionedSchema's checksum comes from the
//  model types it lists *as compiled today*, and `Schema` pulls in every model
//  reachable through a relationship — so a V1 listing only the four 1.x models still
//  resolves to all nine entities and checksums identically to V2. Core Data rejects a
//  plan holding two versions with the same checksum ("Duplicate version checksums
//  detected"). A past version can therefore only appear here as frozen copies of the
//  old model types; since V1 → V2 and V2 → V3 were purely additive, neither needs a
//  stage and SwiftData infers the migration from a 1.x or 1.1 store on its own.
//  `StoreMigrationTests` opens a store the V2 code wrote and holds that to account.
//
//  The identifier still moves with the shape, so a store records which shape it
//  holds and a later stage can name its source exactly. For a purely additive change
//  it is bookkeeping, not what makes the store open: with the V2 fixture, the inferred
//  migration succeeded even when this was left at 2.0.0.
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
/// `Category.group` and `Category.envelopes` (V2) — plus `PlanItem.isFunded` (V3).
enum ExpenseKuSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Expense.self, Category.self, Person.self, Account.self,
         CyclePlan.self, PlanItem.self, IncomeLine.self, TransferLine.self, CategoryGroup.self]
    }
}

enum ExpenseKuMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [ExpenseKuSchemaV3.self]
    }

    static var stages: [MigrationStage] { [] }
}
