//
//  PersonReconcileTests.swift
//  ExpenseKuTests
//
//  Covers Person.reconcileMe — the "exactly one protected Me" guarantee and the
//  healing of duplicate owner records that CloudKit sync can introduce (ADR-0002).
//  Unlike the pure leaderboard tests, these need a real (in-memory) ModelContext
//  because reconcile fetches, re-tags via the inverse relationship, and deletes.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

@MainActor
final class PersonReconcileTests: XCTestCase {

    /// A private in-memory container so the test never touches the host app's
    /// CloudKit-backed store (cloudKitDatabase: .none).
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Expense.self, Category.self, Person.self, Account.self])
        let config = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func fetchMe(_ context: ModelContext) throws -> [Person] {
        try context.fetch(FetchDescriptor<Person>(predicate: #Predicate { $0.isMe }))
    }

    /// First run creates exactly one protected "Me".
    func testCreatesMeOnFirstRun() throws {
        let context = try makeContext()
        Person.reconcileMe(in: context)
        let mes = try fetchMe(context)
        XCTAssertEqual(mes.count, 1)
        XCTAssertEqual(mes.first?.name, "Me")
    }

    /// Reconcile flushes its own work. It runs from the CloudKit remote-change handler,
    /// where autosave may never get a chance to fire before the app is killed — an
    /// unflushed merge is lost on every device and the duplicate "Me" survives.
    func testCreatingMeIsPersisted() throws {
        let context = try makeContext()
        Person.reconcileMe(in: context)
        XCTAssertFalse(context.hasChanges, "the new Me is written, not left pending")
    }

    /// Same guarantee for the healing path, which deletes and re-tags rather than inserts.
    func testMergeIsPersisted() throws {
        let context = try makeContext()
        let a = Person(name: "Me", isMe: true)
        let b = Person(name: "Me", isMe: true)
        [a, b].forEach(context.insert)
        [Expense(amount: 1, people: [a]),
         Expense(amount: 1, people: [a]),
         Expense(amount: 1, people: [b])].forEach(context.insert)

        Person.reconcileMe(in: context)

        XCTAssertFalse(context.hasChanges, "the merge is written, not left pending")
    }

    /// Calling it again is a no-op — it stays at one.
    func testIdempotent() throws {
        let context = try makeContext()
        Person.reconcileMe(in: context)
        Person.reconcileMe(in: context)
        XCTAssertEqual(try fetchMe(context).count, 1)
    }

    /// Two "Me" records (as two devices' first-run inserts would produce after
    /// they sync) collapse into one, and every expense tagged on either keeps a
    /// single "Me" — the one on the losing record is re-tagged onto the survivor.
    func testMergesDuplicateMe() throws {
        let context = try makeContext()
        let a = Person(name: "Me", isMe: true)
        let b = Person(name: "Me", isMe: true)
        let tarisa = Person(name: "Tarisa")
        [a, b, tarisa].forEach(context.insert)

        // `a` is used on two expenses, `b` on one — `a` should win (most-used).
        let e1 = Expense(amount: 100_000, people: [a, tarisa])
        let e2 = Expense(amount: 50_000, people: [a])
        let e3 = Expense(amount: 20_000, people: [b, tarisa])
        [e1, e2, e3].forEach(context.insert)

        Person.reconcileMe(in: context)

        let mes = try fetchMe(context)
        XCTAssertEqual(mes.count, 1, "duplicates collapse into a single Me")
        let survivor = try XCTUnwrap(mes.first)
        XCTAssertTrue(survivor === a, "the more-used record wins")

        // e3's "Me" was re-pointed from b to the survivor; b is gone from it.
        XCTAssertTrue((e3.people ?? []).contains { $0 === survivor })
        XCTAssertFalse((e3.people ?? []).contains { $0 === b })

        // No expense lost its Me and none ended up with two.
        for expense in [e1, e2, e3] {
            XCTAssertEqual((expense.people ?? []).filter(\.isMe).count, 1)
        }
        // Companions are untouched.
        XCTAssertTrue((e1.people ?? []).contains { $0 === tarisa })
        XCTAssertTrue((e3.people ?? []).contains { $0 === tarisa })
    }

    /// The survivor is renamed back to the protected name even if the winning
    /// duplicate had been given a different name on another device.
    func testSurvivorKeepsProtectedName() throws {
        let context = try makeContext()
        // Give the would-be winner more expenses so it's chosen, but a stray name.
        let renamed = Person(name: "Randy", isMe: true)
        let plain = Person(name: "Me", isMe: true)
        [renamed, plain].forEach(context.insert)
        [Expense(amount: 1, people: [renamed]),
         Expense(amount: 1, people: [renamed])].forEach(context.insert)

        Person.reconcileMe(in: context)

        let mes = try fetchMe(context)
        XCTAssertEqual(mes.count, 1)
        XCTAssertEqual(mes.first?.name, "Me")
    }
}
