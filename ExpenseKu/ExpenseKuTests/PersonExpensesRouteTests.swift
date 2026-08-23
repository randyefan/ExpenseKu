//
//  PersonExpensesRouteTests.swift
//  ExpenseKuTests
//
//  A navigation path outlives the objects put into it. The route therefore holds
//  identifiers, not model instances, and resolving one has to report "gone" rather
//  than hand back a deleted model. These cover that, which no screenshot can.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class PersonExpensesRouteTests: XCTestCase {

    @MainActor
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Expense.self, Category.self, Person.self, Account.self])
        let config = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    @MainActor
    func testResolvesWhileTheEntitiesExist() throws {
        let context = try makeContext()
        let tarisa = Person(name: "Tarisa")
        let makan = Category(name: "Makan")
        let cash = Account(name: "Cash")
        context.insert(tarisa)
        context.insert(makan)
        context.insert(cash)
        try context.save()

        let route = PersonExpensesRoute(person: tarisa, category: makan, account: cash, range: .allTime)

        XCTAssertEqual(route.person(in: context)?.name, "Tarisa")
        XCTAssertEqual(route.category(in: context)?.name, "Makan")
        XCTAssertEqual(route.account(in: context)?.name, "Cash")
    }

    /// The case the change exists for: sync from another device, or reconcileMe folding
    /// a duplicate "Me", removes the person while the detail screen is still pushed.
    @MainActor
    func testPersonResolvesToNilOnceDeleted() throws {
        let context = try makeContext()
        let tarisa = Person(name: "Tarisa")
        context.insert(tarisa)
        try context.save()

        let route = PersonExpensesRoute(person: tarisa, category: nil, account: nil, range: .allTime)
        XCTAssertNotNil(route.person(in: context))

        context.delete(tarisa)
        try context.save()

        XCTAssertNil(route.person(in: context))
    }

    /// Category and account have no "Me" protection at all — either can be deleted from
    /// Manage at any moment.
    @MainActor
    func testFiltersResolveToNilOnceDeleted() throws {
        let context = try makeContext()
        let tarisa = Person(name: "Tarisa")
        let makan = Category(name: "Makan")
        let cash = Account(name: "Cash")
        context.insert(tarisa)
        context.insert(makan)
        context.insert(cash)
        try context.save()

        let route = PersonExpensesRoute(person: tarisa, category: makan, account: cash, range: .allTime)

        context.delete(makan)
        context.delete(cash)
        try context.save()

        XCTAssertNotNil(route.person(in: context), "the person outlives its filters")
        XCTAssertNil(route.category(in: context))
        XCTAssertNil(route.account(in: context))
    }

    /// An unfiltered route resolves its optional ids to nil without touching the store.
    @MainActor
    func testAbsentFiltersAreNil() throws {
        let context = try makeContext()
        let tarisa = Person(name: "Tarisa")
        context.insert(tarisa)
        try context.save()

        let route = PersonExpensesRoute(person: tarisa, category: nil, account: nil, range: .allTime)

        XCTAssertNil(route.category(in: context))
        XCTAssertNil(route.account(in: context))
    }

    /// Two routes to the same person and filters are equal, so the nav path dedupes.
    @MainActor
    func testRoutesToTheSameTargetAreEqual() throws {
        let context = try makeContext()
        let tarisa = Person(name: "Tarisa")
        context.insert(tarisa)
        try context.save()

        let a = PersonExpensesRoute(person: tarisa, category: nil, account: nil, range: .allTime)
        let b = PersonExpensesRoute(person: tarisa, category: nil, account: nil, range: .allTime)
        XCTAssertEqual(a, b)
    }
}
