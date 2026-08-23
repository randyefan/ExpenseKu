//
//  AccountAnalyticsTests.swift
//  ExpenseKuTests
//
//  Covers the new account aggregations: SpendSummary.byAccount (incl. the
//  "Unassigned" bucket for nil-account expenses) and the account filter on
//  PeopleLeaderboard.ranked. Uses un-inserted model objects (no ModelContext) so
//  the tests stay pure and avoid a second ModelContainer fighting the test host's
//  own — same pattern as the existing analytics tests.
//

import XCTest
@testable import ExpenseKu

// Under @testable import, XCTest's transitive imports also expose an
// OpaquePointer `Category`, making the bare name ambiguous here (it isn't in the
// app module). Pin it to our model. `Account` is unambiguous, so it needs no alias.
private typealias Category = ExpenseKu.Category

nonisolated final class AccountAnalyticsTests: XCTestCase {

    // MARK: - SpendSummary.byAccount

    /// Account totals are summed and ordered highest-first.
    func testByAccountSortedDescending() {
        let cash = Account(name: "Cash")
        let gopay = Account(name: "GoPay")
        let expenses = [
            Expense(amount: 30_000, account: cash),
            Expense(amount: 70_000, account: cash),
            Expense(amount: 40_000, account: gopay),
        ]

        let summary = SpendSummary.byAccount(from: expenses)

        XCTAssertEqual(summary.map(\.accountName), ["Cash", "GoPay"])
        XCTAssertEqual(summary[0].total, 100_000)
        XCTAssertEqual(summary[1].total, 40_000)
    }

    /// Expenses with no account land in an "Unassigned" bucket.
    func testByAccountUnassignedBucket() {
        let cash = Account(name: "Cash")
        let expenses = [
            Expense(amount: 25_000, account: nil),
            Expense(amount: 15_000, account: nil),
            Expense(amount: 60_000, account: cash),
        ]

        let summary = SpendSummary.byAccount(from: expenses)

        XCTAssertEqual(summary.map(\.accountName), ["Cash", "Unassigned"])
        XCTAssertEqual(summary[0].total, 60_000)
        XCTAssertEqual(summary[1].accountName, "Unassigned")
        XCTAssertEqual(summary[1].total, 40_000)      // 25k + 15k
    }

    /// The date range filter applies to the account summary too.
    func testByAccountHonorsDateRange() {
        let cash = Account(name: "Cash")
        let expenses = [
            Expense(amount: 100_000, date: date(2026, 1, 15), account: cash),
            Expense(amount: 40_000, date: date(2026, 6, 15), account: cash),
        ]

        let juneOnly = date(2026, 6, 1)...date(2026, 6, 30)
        let summary = SpendSummary.byAccount(from: expenses, dateRange: juneOnly)

        XCTAssertEqual(summary.count, 1)
        XCTAssertEqual(summary[0].accountName, "Cash")
        XCTAssertEqual(summary[0].total, 40_000)
    }

    // MARK: - PeopleLeaderboard.ranked(account:)

    /// The account filter restricts which expenses count toward the ranking.
    func testAccountFilterRestrictsRanking() {
        let cash = Account(name: "Cash")
        let gopay = Account(name: "GoPay")
        let tarisa = Person(name: "Tarisa")
        let expenses = [
            Expense(amount: 100_000, people: [tarisa], account: gopay),
            Expense(amount: 40_000, people: [tarisa], account: cash),
        ]

        let ranked = PeopleLeaderboard.ranked(from: expenses, account: gopay)

        XCTAssertEqual(ranked.count, 1)
        XCTAssertEqual(ranked[0].total, 100_000)
        XCTAssertEqual(ranked[0].sharedCount, 1)
    }

    /// Expenses with no account are excluded once an account filter is active.
    func testAccountFilterExcludesUnassigned() {
        let gopay = Account(name: "GoPay")
        let tarisa = Person(name: "Tarisa")
        let expenses = [
            Expense(amount: 100_000, people: [tarisa], account: gopay),
            Expense(amount: 40_000, people: [tarisa], account: nil),
        ]

        let ranked = PeopleLeaderboard.ranked(from: expenses, account: gopay)

        XCTAssertEqual(ranked.count, 1)
        XCTAssertEqual(ranked[0].total, 100_000)
    }

    /// The account filter combines with the category filter (both must match).
    func testAccountAndCategoryFiltersCombine() {
        let makan = Category(name: "Makan")
        let transport = Category(name: "Transport")
        let gopay = Account(name: "GoPay")
        let cash = Account(name: "Cash")
        let tarisa = Person(name: "Tarisa")
        let expenses = [
            Expense(amount: 100_000, category: makan, people: [tarisa], account: gopay),      // matches both
            Expense(amount: 50_000, category: transport, people: [tarisa], account: gopay),   // wrong category
            Expense(amount: 30_000, category: makan, people: [tarisa], account: cash),        // wrong account
        ]

        let ranked = PeopleLeaderboard.ranked(from: expenses, category: makan, account: gopay)

        XCTAssertEqual(ranked.count, 1)
        XCTAssertEqual(ranked[0].total, 100_000)
        XCTAssertEqual(ranked[0].sharedCount, 1)
    }

    /// With no account filter, every expense still counts (regression guard).
    func testNoAccountFilterCountsEverything() {
        let gopay = Account(name: "GoPay")
        let tarisa = Person(name: "Tarisa")
        let expenses = [
            Expense(amount: 100_000, people: [tarisa], account: gopay),
            Expense(amount: 40_000, people: [tarisa], account: nil),
        ]

        let ranked = PeopleLeaderboard.ranked(from: expenses)

        XCTAssertEqual(ranked.count, 1)
        XCTAssertEqual(ranked[0].total, 140_000)
        XCTAssertEqual(ranked[0].sharedCount, 2)
    }

    // MARK: - Helpers

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: year, month: month, day: day))!
    }
}
