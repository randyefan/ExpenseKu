//
//  ExistingEntityTests.swift
//  ExpenseKuTests
//
//  The ADR-0002 duplicate check, exercised against every NamedEntity type.
//  Run under Release too: `propertiesToFetch = [\.name]` on the generic `T` passes in
//  Debug but traps inside SwiftData once optimized.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class ExistingEntityTests: XCTestCase {

    @MainActor
    private func makeContext() throws -> ModelContext {
        try makeInMemoryContext()
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

    @MainActor
    func testFindsGroupIgnoringCase() throws {
        let context = try makeContext()
        context.insert(CategoryGroup(name: "Needs"))
        try context.save()

        XCTAssertNotNil(existingEntity(CategoryGroup.self, matching: "needs", in: context))
        XCTAssertNil(existingEntity(CategoryGroup.self, matching: "Wants", in: context))
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

    /// The returned entity is live: every field is readable, not just the name.
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
