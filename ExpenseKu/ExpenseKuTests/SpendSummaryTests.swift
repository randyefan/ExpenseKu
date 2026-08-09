//
//  SpendSummaryTests.swift
//  ExpenseKuTests
//
//  Covers the category and over-time aggregations of the pure SpendSummary
//  layer. Uses un-inserted model objects (no ModelContext) so the tests stay
//  pure and avoid a second ModelContainer fighting the test host's own.
//

import XCTest
@testable import ExpenseKu

// Under @testable import, XCTest's transitive imports also expose an
// OpaquePointer `Category`, making the bare name ambiguous here (it isn't in
// the app module). Pin it to our model.
private typealias Category = ExpenseKu.Category

final class SpendSummaryTests: XCTestCase {

    /// Category totals are summed and ordered highest-first.
    func testByCategorySortedDescending() {
        let makan = Category(name: "Makan")
        let transport = Category(name: "Transport")
        let expenses = [
            Expense(amount: 30_000, category: makan),
            Expense(amount: 70_000, category: makan),
            Expense(amount: 40_000, category: transport),
        ]

        let summary = SpendSummary.byCategory(from: expenses)

        XCTAssertEqual(summary.map(\.categoryName), ["Makan", "Transport"])
        XCTAssertEqual(summary[0].total, 100_000)
        XCTAssertEqual(summary[1].total, 40_000)
    }

    /// Expenses with no category land in an "Uncategorized" bucket.
    func testByCategoryUncategorizedBucket() {
        let expense = Expense(amount: 25_000, category: nil)

        let summary = SpendSummary.byCategory(from: [expense])

        XCTAssertEqual(summary.count, 1)
        XCTAssertEqual(summary[0].categoryName, "Uncategorized")
        XCTAssertEqual(summary[0].total, 25_000)
    }

    /// Spend is bucketed by month and returned in ascending date order.
    func testOverTimeMonthBuckets() {
        let expenses = [
            Expense(amount: 10_000, date: date(2026, 1, 5)),
            Expense(amount: 15_000, date: date(2026, 1, 20)),
            Expense(amount: 40_000, date: date(2026, 3, 2)),
        ]

        let summary = SpendSummary.overTime(from: expenses, granularity: .month)

        XCTAssertEqual(summary.count, 2)             // January + March
        XCTAssertEqual(summary[0].total, 25_000)     // 10k + 15k in January
        XCTAssertEqual(summary[1].total, 40_000)     // March
        XCTAssertLessThan(summary[0].date, summary[1].date)
    }

    /// The date range filter applies to the category summary too.
    func testByCategoryHonorsDateRange() {
        let makan = Category(name: "Makan")
        let expenses = [
            Expense(amount: 100_000, date: date(2026, 1, 15), category: makan),
            Expense(amount: 40_000, date: date(2026, 6, 15), category: makan),
        ]

        let juneOnly = date(2026, 6, 1)...date(2026, 6, 30)
        let summary = SpendSummary.byCategory(from: expenses, dateRange: juneOnly)

        XCTAssertEqual(summary.count, 1)
        XCTAssertEqual(summary[0].total, 40_000)
    }

    // MARK: - Helpers

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: year, month: month, day: day))!
    }
}
