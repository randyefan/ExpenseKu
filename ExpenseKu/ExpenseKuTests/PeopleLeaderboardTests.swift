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

nonisolated final class PeopleLeaderboardTests: XCTestCase {

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

    /// The protected owner ("Me") is never ranked — the board lists companions.
    func testMeIsExcludedFromRanking() {
        let me = Person(name: "Me", isMe: true)
        let tarisa = Person(name: "Tarisa")
        let expenses = [
            Expense(amount: 100_000, people: [me, tarisa]),
            Expense(amount: 50_000, people: [me]),   // solo — contributes nothing
        ]

        let ranked = PeopleLeaderboard.ranked(from: expenses)

        XCTAssertEqual(ranked.map(\.person.name), ["Tarisa"])
        XCTAssertEqual(ranked[0].total, 100_000)
        XCTAssertFalse(ranked.contains { $0.person.isMe })
    }

    // MARK: - expenses(for:) — the person drill-down

    /// Returns only the expenses the given person is tagged on; others are excluded.
    func testExpensesForPersonFiltersByPerson() {
        let tarisa = Person(name: "Tarisa")
        let fadil = Person(name: "Fadil")
        let a = Expense(amount: 100_000, people: [tarisa, fadil])
        let b = Expense(amount: 40_000, people: [fadil])          // no Tarisa
        let c = Expense(amount: 10_000, people: [])               // nobody

        let result = PeopleLeaderboard.expenses(for: tarisa, from: [a, b, c])

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.contains { $0 === a })
    }

    /// The list is sorted newest-first by date.
    func testExpensesForPersonSortedNewestFirst() {
        let tarisa = Person(name: "Tarisa")
        let older = Expense(amount: 10_000, date: date(2026, 1, 10), people: [tarisa])
        let newer = Expense(amount: 20_000, date: date(2026, 3, 20), people: [tarisa])
        let middle = Expense(amount: 30_000, date: date(2026, 2, 15), people: [tarisa])

        let result = PeopleLeaderboard.expenses(for: tarisa, from: [older, newer, middle])

        XCTAssertEqual(result.map(\.date), [newer.date, middle.date, older.date])
    }

    /// category / account / dateRange gate the drill-down the same way as `ranked`.
    func testExpensesForPersonHonorsFilters() {
        let makan = Category(name: "Makan")
        let transport = Category(name: "Transport")
        let cash = Account(name: "Cash")
        let gopay = Account(name: "GoPay")
        let tarisa = Person(name: "Tarisa")
        let keep = Expense(amount: 100_000, date: date(2026, 6, 10),
                           category: makan, people: [tarisa], account: cash)
        let wrongCat = Expense(amount: 40_000, date: date(2026, 6, 11),
                               category: transport, people: [tarisa], account: cash)
        let wrongAcct = Expense(amount: 40_000, date: date(2026, 6, 12),
                                category: makan, people: [tarisa], account: gopay)
        let wrongDate = Expense(amount: 40_000, date: date(2026, 1, 1),
                                category: makan, people: [tarisa], account: cash)

        let result = PeopleLeaderboard.expenses(
            for: tarisa, from: [keep, wrongCat, wrongAcct, wrongDate],
            category: makan, account: cash,
            dateRange: date(2026, 6, 1)...date(2026, 6, 30)
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertTrue(result.contains { $0 === keep })
    }

    /// A person tagged on nothing (under the active filter) yields an empty list —
    /// this is what drives the detail screen's empty state.
    func testExpensesForPersonEmptyWhenNothingMatches() {
        let makan = Category(name: "Makan")
        let transport = Category(name: "Transport")
        let tarisa = Person(name: "Tarisa")
        let expense = Expense(amount: 100_000, category: transport, people: [tarisa])

        let result = PeopleLeaderboard.expenses(for: tarisa, from: [expense], category: makan)

        XCTAssertTrue(result.isEmpty)
    }

    /// The drill-down reconciles with the leaderboard row: under identical filters the
    /// person's expense list count == the row's sharedCount and its amount-sum == total.
    func testExpensesForPersonReconcilesWithRankedRow() {
        let makan = Category(name: "Makan")
        let tarisa = Person(name: "Tarisa")
        let fadil = Person(name: "Fadil")
        let expenses = [
            Expense(amount: 120_000, date: date(2026, 3, 1), category: makan, people: [tarisa, fadil]),
            Expense(amount: 45_000, date: date(2026, 3, 5), category: makan, people: [tarisa]),
            Expense(amount: 30_000, date: date(2026, 3, 8), category: makan, people: [fadil]),
        ]

        let row = PeopleLeaderboard.ranked(from: expenses).first { $0.person === tarisa }
        let list = PeopleLeaderboard.expenses(for: tarisa, from: expenses)

        XCTAssertEqual(list.count, row?.sharedCount)
        XCTAssertEqual(list.reduce(Decimal(0)) { $0 + $1.amount }, row?.total)
    }

    // MARK: - total (the share denominator)

    /// The denominator is everything spent in the window, tagged or not — an expense
    /// with no companion is still your spending.
    func testTotalCountsUntaggedExpenses() {
        let tarisa = Person(name: "Tarisa")
        let expenses = [
            Expense(amount: 100_000, date: date(2026, 3, 1), people: [tarisa]),
            Expense(amount: 40_000, date: date(2026, 3, 2)),
        ]

        XCTAssertEqual(PeopleLeaderboard.total(from: expenses), 140_000)
    }

    /// It honours the same category, account and date filters as the drill-down, so a
    /// share compares like with like.
    func testTotalHonoursTheSameFilters() {
        let makan = Category(name: "Makan")
        let kopi = Category(name: "Kopi")
        let cash = Account(name: "Cash")
        let gopay = Account(name: "GoPay")
        let expenses = [
            Expense(amount: 100_000, date: date(2026, 3, 1), category: makan, account: cash),
            Expense(amount: 40_000, date: date(2026, 3, 2), category: kopi, account: cash),
            Expense(amount: 25_000, date: date(2026, 3, 3), category: makan, account: gopay),
            Expense(amount: 60_000, date: date(2026, 5, 1), category: makan, account: cash),
        ]
        let march = date(2026, 3, 1)...date(2026, 3, 31)

        XCTAssertEqual(
            PeopleLeaderboard.total(from: expenses, category: makan, account: cash, dateRange: march),
            100_000
        )
    }

    /// A share is undefined rather than 0% when the window holds no spending at all.
    func testShareIsNilWhenNothingWasSpent() {
        XCTAssertNil(PersonExpensesView.share(of: 0, in: 0))
        XCTAssertEqual(PersonExpensesView.share(of: 25_000, in: 100_000) ?? 0, 0.25, accuracy: 0.0001)
    }

    /// The empty message reads as a sentence for every window — the chip labels do not
    /// ("no expenses in all time", "no expenses in this month").
    func testEmptyMessageReadsAsASentenceForEveryWindow() {
        for range in DateRangeFilter.allCases {
            let message = PersonExpensesView.emptyMessage(
                name: "Tarisa", filterSummary: nil, range: range
            )
            XCTAssertFalse(message.contains("in all time"), message)
            XCTAssertFalse(message.contains("in this month"), message)
            XCTAssertTrue(message.hasSuffix("."), message)
        }
    }

    // MARK: - Helpers

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: year, month: month, day: day))!
    }
}
