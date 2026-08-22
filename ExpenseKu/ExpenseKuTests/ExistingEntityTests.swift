//
//  ExistingEntityTests.swift
//  ExpenseKuTests
//
//  The ADR-0002 duplicate check. Exercised against all three named entities because
//  `existingEntity` is generic over the protocol, and the fetch it builds narrows to
//  `\.name` — a key path to a protocol requirement, not to a concrete stored property.
//  Whether SwiftData can map that is the open question this file answers.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class ExistingEntityTests: XCTestCase {

    @MainActor
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Expense.self, Category.self, Person.self, Account.self])
        let config = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    // MARK: - Category

    @MainActor
    func testFindsCategoryIgnoringCase() throws {
        let context = try makeContext()
        context.insert(Category(name: "Makan"))
        try context.save()

        XCTAssertNotNil(existingEntity(Category.self, matching: "makan", in: context))
        XCTAssertNotNil(existingEntity(Category.self, matching: "  MAKAN  ", in: context))
        XCTAssertNil(existingEntity(Category.self, matching: "Transport", in: context))
    }

    /// The renamed entity must not collide with itself.
    @MainActor
    func testExcludingSkipsTheEntityBeingRenamed() throws {
        let context = try makeContext()
        let makan = Category(name: "Makan")
        context.insert(makan)
        try context.save()

        XCTAssertNil(existingEntity(Category.self, matching: "Makan", in: context, excluding: makan))
        XCTAssertNotNil(existingEntity(Category.self, matching: "Makan", in: context))
    }

    // MARK: - Person and Account

    @MainActor
    func testFindsPersonIgnoringCase() throws {
        let context = try makeContext()
        context.insert(Person(name: "Tarisa"))
        try context.save()

        XCTAssertNotNil(existingEntity(Person.self, matching: "tarisa", in: context))
        XCTAssertNil(existingEntity(Person.self, matching: "Budi", in: context))
    }

    @MainActor
    func testFindsAccountIgnoringCase() throws {
        let context = try makeContext()
        context.insert(Account(name: "GoPay"))
        try context.save()

        XCTAssertNotNil(existingEntity(Account.self, matching: "gopay", in: context))
        XCTAssertNil(existingEntity(Account.self, matching: "Cash", in: context))
    }

    // MARK: - Edges

    @MainActor
    func testBlankNameNeverMatches() throws {
        let context = try makeContext()
        context.insert(Category(name: "Makan"))
        try context.save()

        XCTAssertNil(existingEntity(Category.self, matching: "", in: context))
        XCTAssertNil(existingEntity(Category.self, matching: "   ", in: context))
    }

    /// The returned entity is live: fields the fetch did not load must still fault in.
    @MainActor
    func testUnfetchedPropertiesStillReadable() throws {
        let context = try makeContext()
        context.insert(Category(name: "Makan", colorHex: "FFCC00", iconName: "fork.knife"))
        try context.save()

        let found = try XCTUnwrap(existingEntity(Category.self, matching: "makan", in: context))
        XCTAssertEqual(found.colorHex, "FFCC00")
        XCTAssertEqual(found.iconName, "fork.knife")
        XCTAssertEqual(found.resolvedSymbol, "fork.knife")
    }
}
