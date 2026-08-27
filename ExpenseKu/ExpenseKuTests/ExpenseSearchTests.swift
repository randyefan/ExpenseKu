//
//  ExpenseSearchTests.swift
//  ExpenseKuTests
//
//  Behaviour oracle for the expense-search feature: one query box that searches
//  every expense ever logged, matching a note, a category, a companion or an
//  account, narrowed by an optional category + date range. Pure — no
//  ModelContainer — with a fixed gregorian calendar for determinism.
//

import XCTest
@testable import ExpenseKu

nonisolated final class ExpenseSearchTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    // MARK: - What a query matches

    /// The note is searchable, and case does not matter.
    func testMatchesNoteIgnoringCase() {
        let expense = Expense(amount: 25_000, date: date(2026, 8, 2), note: "Morning coffee")

        XCTAssertEqual(results("COFFEE", [expense]).count, 1)
        XCTAssertEqual(results("coffee", [expense]).count, 1)
    }

    /// A category's name is searchable even when the note says nothing.
    func testMatchesCategoryName() {
        let expense = Expense(amount: 25_000, date: date(2026, 8, 2), category: Category(name: "Kopi"))

        XCTAssertEqual(results("kopi", [expense]).count, 1)
    }

    /// A companion's name is searchable.
    func testMatchesPersonName() {
        let expense = Expense(
            amount: 120_000, date: date(2026, 8, 2), note: "Dinner",
            people: [Person(name: "Tarisa"), Person(name: "Fadil")]
        )

        XCTAssertEqual(results("fadil", [expense]).count, 1)
    }

    /// The account's name is searchable.
    func testMatchesAccountName() {
        let expense = Expense(
            amount: 30_000, date: date(2026, 8, 2), note: "Grab home",
            account: Account(name: "GoPay")
        )

        XCTAssertEqual(results("gopay", [expense]).count, 1)
    }

    /// Matching folds diacritics, so an unaccented query finds accented text.
    func testMatchingIsDiacriticInsensitive() {
        let expense = Expense(amount: 55_000, date: date(2026, 6, 11), note: "Café Kenangan")

        XCTAssertEqual(results("cafe", [expense]).count, 1)
    }

    /// A query that matches nothing returns nothing — and totals zero.
    func testNoMatchReturnsEmpty() {
        let expense = Expense(amount: 25_000, date: date(2026, 8, 2), note: "Morning coffee")

        let found = results("xyzzy", [expense])

        XCTAssertTrue(found.isEmpty)
        XCTAssertEqual(found.count, 0)
        XCTAssertEqual(found.total, 0)
    }

    /// An empty or whitespace-only query returns nothing, never everything —
    /// "no query" must not be read as "match all".
    func testEmptyQueryReturnsNothing() {
        let expense = Expense(amount: 25_000, date: date(2026, 8, 2), note: "Morning coffee")

        XCTAssertTrue(results("", [expense]).isEmpty)
        XCTAssertTrue(results("   ", [expense]).isEmpty)
    }

    /// "Uncategorized" is how the UI renders a missing category, not the owner's
    /// data — so it must not match an expense that simply has no category.
    func testUncategorizedIsNotSearchableText() {
        let expense = Expense(amount: 45_000, date: date(2026, 8, 2), note: "Lunch")

        XCTAssertTrue(results("uncategorized", [expense]).isEmpty)
    }

    /// An expense with no category, no account and no companions still matches
    /// on its note, without crashing on the nil relationships.
    func testBareExpenseStillMatchesOnNote() {
        let expense = Expense(amount: 45_000, date: date(2026, 8, 2), note: "Lunch")

        XCTAssertEqual(results("lunch", [expense]).count, 1)
    }

    // MARK: - Multi-word queries

    /// Every whitespace-separated token must match — across different fields, so
    /// "kopi cash" finds the Kopi expense paid from Cash.
    func testAllTokensMustMatch() {
        let cash = Expense(
            amount: 25_000, date: date(2026, 8, 2), note: "Latte",
            category: Category(name: "Kopi"), account: Account(name: "Cash")
        )
        let gopay = Expense(
            amount: 22_000, date: date(2026, 8, 3), note: "Latte",
            category: Category(name: "Kopi"), account: Account(name: "GoPay")
        )

        let found = results("kopi cash", [cash, gopay])

        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found.expenses.first?.account?.name, "Cash")
    }

    /// One unmatched token disqualifies the expense, even if the rest match.
    func testUnmatchedTokenExcludes() {
        let expense = Expense(
            amount: 25_000, date: date(2026, 8, 2), note: "Latte",
            category: Category(name: "Kopi")
        )

        XCTAssertTrue(results("kopi zzz", [expense]).isEmpty)
    }

    // MARK: - Ordering and totals

    /// Results come back newest first regardless of the input order.
    func testResultsAreNewestFirst() {
        let old = Expense(amount: 1, date: date(2025, 12, 18), note: "kopi old")
        let mid = Expense(amount: 1, date: date(2026, 7, 20), note: "kopi mid")
        let new = Expense(amount: 1, date: date(2026, 8, 2), note: "kopi new")

        let found = results("kopi", [mid, new, old])

        XCTAssertEqual(found.expenses.map(\.note), ["kopi new", "kopi mid", "kopi old"])
    }

    /// The total sums the matches only — never the whole store.
    func testTotalSumsMatchesOnly() {
        let hit1 = Expense(amount: 25_000, date: date(2026, 8, 2), note: "kopi a")
        let hit2 = Expense(amount: 35_000, date: date(2026, 8, 3), note: "kopi b")
        let miss = Expense(amount: 999_000, date: date(2026, 8, 4), note: "rent")

        let found = results("kopi", [hit1, hit2, miss])

        XCTAssertEqual(found.count, 2)
        XCTAssertEqual(found.total, 60_000)
        XCTAssertEqual(found.count, found.expenses.count)
    }

    // MARK: - Filters

    /// The category filter narrows both the results and the total.
    func testCategoryFilterNarrowsResults() {
        let kopi = Expense(
            amount: 25_000, date: date(2026, 8, 2), note: "kopi a",
            category: Category(name: "Kopi")
        )
        let makan = Expense(
            amount: 35_000, date: date(2026, 8, 3), note: "kopi b",
            category: Category(name: "Makan")
        )

        let found = results("kopi", [kopi, makan], categoryName: "Kopi")

        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found.total, 25_000)
    }

    /// A date range narrows the results.
    func testDateRangeFilterNarrowsResults() {
        let inside = Expense(amount: 25_000, date: date(2026, 8, 2), note: "kopi in")
        let outside = Expense(amount: 35_000, date: date(2025, 12, 18), note: "kopi out")

        let found = results("kopi", [inside, outside], dateRange: date(2026, 1, 1)...date(2026, 12, 31))

        XCTAssertEqual(found.expenses.map(\.note), ["kopi in"])
    }

    /// Both ends of the range are inclusive.
    func testDateRangeBoundsAreInclusive() {
        let start = date(2026, 8, 1)
        let end = date(2026, 8, 31)
        let first = Expense(amount: 1, date: start, note: "kopi first")
        let last = Expense(amount: 1, date: end, note: "kopi last")

        let found = results("kopi", [first, last], dateRange: start...end)

        XCTAssertEqual(found.count, 2)
    }

    /// Query, category and range all apply together — each of the three rejects
    /// its own decoy. The query term is deliberately *not* a category name, so
    /// `wrongQuery` is excluded by the query alone and not by the filter.
    func testQueryAndBothFiltersCompose() {
        let match = Expense(
            amount: 25_000, date: date(2026, 8, 2), note: "latte keep",
            category: Category(name: "Kopi")
        )
        let wrongCategory = Expense(
            amount: 25_000, date: date(2026, 8, 2), note: "latte drop",
            category: Category(name: "Makan")
        )
        let wrongDate = Expense(
            amount: 25_000, date: date(2025, 8, 2), note: "latte drop",
            category: Category(name: "Kopi")
        )
        let wrongQuery = Expense(
            amount: 25_000, date: date(2026, 8, 2), note: "rent",
            category: Category(name: "Kopi")
        )

        let found = results(
            "latte", [match, wrongCategory, wrongDate, wrongQuery],
            categoryName: "Kopi",
            dateRange: date(2026, 1, 1)...date(2026, 12, 31)
        )

        XCTAssertEqual(found.expenses.map(\.note), ["latte keep"])
    }

    /// A query that matches only via the category name still counts — the point
    /// of one box over four. (This is what the compose test's decoy tripped on.)
    func testCategoryNameAloneIsEnoughToMatch() {
        let expense = Expense(
            amount: 25_000, date: date(2026, 8, 2), note: "rent",
            category: Category(name: "Kopi")
        )

        XCTAssertEqual(results("kopi", [expense]).count, 1)
    }

    // MARK: - Helpers

    private func results(
        _ query: String,
        _ expenses: [Expense],
        categoryName: String? = nil,
        dateRange: ClosedRange<Date>? = nil
    ) -> ExpenseSearchResults {
        ExpenseSearchResults(
            query: query,
            allExpenses: expenses,
            categoryName: categoryName,
            dateRange: dateRange
        )
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }
}
