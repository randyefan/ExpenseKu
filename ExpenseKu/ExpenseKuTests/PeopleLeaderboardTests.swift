//
//  PeopleLeaderboardTests.swift
//  ExpenseKuTests
//
//  Covers the attribution rule and filters of the pure PeopleLeaderboard layer.
//  Uses un-inserted model objects (no ModelContext) — the aggregation operates
//  on a plain [Expense], so tests stay pure and avoid a second ModelContainer
//  fighting the test host app's own container.
//

import XCTest
@testable import ExpenseKu

// Under @testable import, XCTest's transitive imports also expose an
// OpaquePointer `Category`, making the bare name ambiguous here (it isn't in
// the app module). Pin it to our model.
private typealias Category = ExpenseKu.Category

final class PeopleLeaderboardTests: XCTestCase {

    /// The full amount is credited to each companion — a 100k expense with two
    /// people counts 100k toward each (not split).
    func testFullAmountToEachCompanion() {
        let makan = Category(name: "Makan")
        let tarisa = Person(name: "Tarisa")
        let fadil = Person(name: "Fadil")
        let expense = Expense(amount: 100_000, category: makan, people: [tarisa, fadil])

        let ranked = PeopleLeaderboard.ranked(from: [expense])

        XCTAssertEqual(ranked.count, 2)
        XCTAssertEqual(ranked[0].total, 100_000)
        XCTAssertEqual(ranked[1].total, 100_000)
        XCTAssertEqual(ranked[0].sharedCount, 1)
        XCTAssertEqual(Set(ranked.map(\.person.name)), ["Tarisa", "Fadil"])
    }

    /// Totals accumulate across expenses and rank highest-first.
    func testRankingByTotalDescending() {
        let tarisa = Person(name: "Tarisa")
        let fadil = Person(name: "Fadil")
        let expenses = [
            Expense(amount: 100_000, people: [tarisa]),
            Expense(amount: 30_000, people: [tarisa, fadil]),
        ]

        let ranked = PeopleLeaderboard.ranked(from: expenses)

        XCTAssertEqual(ranked.map(\.person.name), ["Tarisa", "Fadil"])
        XCTAssertEqual(ranked[0].total, 130_000)   // 100k + 30k
        XCTAssertEqual(ranked[0].sharedCount, 2)
        XCTAssertEqual(ranked[1].total, 30_000)
        XCTAssertEqual(ranked[1].sharedCount, 1)
    }

    /// The category filter restricts which expenses count.
    func testCategoryFilter() {
        let makan = Category(name: "Makan")
        let transport = Category(name: "Transport")
        let tarisa = Person(name: "Tarisa")
        let expenses = [
            Expense(amount: 100_000, category: makan, people: [tarisa]),
            Expense(amount: 40_000, category: transport, people: [tarisa]),
        ]

        let ranked = PeopleLeaderboard.ranked(from: expenses, category: makan)

        XCTAssertEqual(ranked.count, 1)
        XCTAssertEqual(ranked[0].total, 100_000)
    }

    /// The date range filter restricts which expenses count.
    func testDateRangeFilter() {
        let tarisa = Person(name: "Tarisa")
        let expenses = [
            Expense(amount: 100_000, date: date(2026, 1, 15), people: [tarisa]),
            Expense(amount: 40_000, date: date(2026, 6, 15), people: [tarisa]),
        ]

        let juneOnly = date(2026, 6, 1)...date(2026, 6, 30)
        let ranked = PeopleLeaderboard.ranked(from: expenses, dateRange: juneOnly)

        XCTAssertEqual(ranked.count, 1)
        XCTAssertEqual(ranked[0].total, 40_000)
    }

    /// Expenses with no people are ignored entirely.
    func testExpensesWithoutPeopleAreIgnored() {
        let expense = Expense(amount: 100_000, people: [])
        XCTAssertTrue(PeopleLeaderboard.ranked(from: [expense]).isEmpty)
    }

    // MARK: - Helpers

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: year, month: month, day: day))!
    }
}
