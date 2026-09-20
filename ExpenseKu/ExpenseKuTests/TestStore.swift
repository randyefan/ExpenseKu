//
//  TestStore.swift
//  ExpenseKuTests
//
//  One in-memory ModelContext for every SwiftData test, built from the *shipping*
//  versioned schema rather than a hand-written model list. Three test files used to
//  each carry their own `Schema([Expense.self, Category.self, Person.self,
//  Account.self])`, which meant every schema version had to be remembered in four
//  places and silently drifted in the fourth.
//
//  `cloudKitDatabase: .none` keeps the test off the host app's mirrored store; the
//  unsigned test host could not reach it anyway.
//

import Foundation
import SwiftData
import XCTest
@testable import ExpenseKu

@MainActor
func makeInMemoryContext() throws -> ModelContext {
    let schema = Schema(versionedSchema: ExpenseKuSchemaV2.self)
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    return ModelContext(try ModelContainer(for: schema, configurations: [config]))
}
