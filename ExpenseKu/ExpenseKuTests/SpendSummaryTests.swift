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

nonisolated final class SpendSummaryTests: XCTestCase {

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

    // MARK: - Pay-period buckets

    /// A pay cycle splits the calendar month at the payday: the 24th and the 26th of
    /// the same July fall in different buckets when payday is the 25th.
    func testOverTimePayPeriodSplitsTheMonthAtPayday() {
        let expenses = [
            Expense(amount: 10_000, date: date(2026, 7, 24)),
            Expense(amount: 15_000, date: date(2026, 7, 26)),
            Expense(amount: 40_000, date: date(2026, 8, 10)),
        ]

        let summary = SpendSummary.overTime(
            from: expenses, granularity: .payPeriod(payday: 25), calendar: gregorian
        )

        XCTAssertEqual(summary.count, 2)
        XCTAssertEqual(summary[0].total, 10_000)     // 25 Jun – 24 Jul
        XCTAssertEqual(summary[1].total, 55_000)     // 25 Jul – 24 Aug
    }

    /// Each bucket is keyed by the month its cycle *ends* in — PayCycle's title
    /// convention — so a 25 Jul – 24 Aug cycle sits under August.
    func testOverTimePayPeriodKeysByEndingMonth() {
        let expenses = [Expense(amount: 10_000, date: date(2026, 7, 26))]

        let summary = SpendSummary.overTime(
            from: expenses, granularity: .payPeriod(payday: 25), calendar: gregorian
        )

        XCTAssertEqual(summary.map(\.date), [date(2026, 8, 1)])
    }

    /// Payday 1 makes a pay cycle exactly a calendar month, so both granularities agree.
    func testOverTimePayPeriodWithPaydayOneMatchesMonthBuckets() {
        let expenses = [
            Expense(amount: 10_000, date: date(2026, 1, 5)),
            Expense(amount: 15_000, date: date(2026, 1, 20)),
            Expense(amount: 40_000, date: date(2026, 3, 2)),
        ]

        let byMonth = SpendSummary.overTime(
            from: expenses, granularity: .month, calendar: gregorian
        )
        let byPayPeriod = SpendSummary.overTime(
            from: expenses, granularity: .payPeriod(payday: 1), calendar: gregorian
        )

        XCTAssertEqual(byPayPeriod.map(\.date), byMonth.map(\.date))
        XCTAssertEqual(byPayPeriod.map(\.total), byMonth.map(\.total))
    }

    /// A payday the month is too short for clamps (31 → Feb 28), and the shortened
    /// cycle still gets its own bucket rather than merging with its neighbour.
    func testOverTimePayPeriodClampsShortMonthsIntoDistinctBuckets() {
        let expenses = [
            Expense(amount: 10_000, date: date(2026, 2, 20)),   // 31 Jan – 27 Feb
            Expense(amount: 15_000, date: date(2026, 2, 28)),   // 28 Feb – 30 Mar
            Expense(amount: 40_000, date: date(2026, 3, 1)),    // 28 Feb – 30 Mar
        ]

        let summary = SpendSummary.overTime(
            from: expenses, granularity: .payPeriod(payday: 31), calendar: gregorian
        )

        XCTAssertEqual(summary.map(\.date), [date(2026, 2, 1), date(2026, 3, 1)])
        XCTAssertEqual(summary.map(\.total), [10_000, 55_000])
    }

    // MARK: - The pay-period trend window

    /// The window is ascending and ends with the cycle you are in right now.
    func testPayPeriodWindowEndsWithTheCurrentCycle() {
        let window = SpendSummary.payPeriodWindow(
            cycles: 3, payday: 25, now: date(2026, 8, 30), calendar: gregorian
        )

        XCTAssertEqual(window.count, 3)
        XCTAssertEqual(window.map(\.start), [date(2026, 6, 25), date(2026, 7, 25), date(2026, 8, 25)])
        XCTAssertTrue(window.last!.contains(date(2026, 8, 30)))
    }

    /// On 30 August with payday 25 you are already in the cycle that ends 24 September,
    /// so the current period charts as September — not August.
    func testCurrentPeriodOnThirtiethOfAugustIsSeptember() {
        let window = SpendSummary.payPeriodWindow(
            cycles: 3, payday: 25, now: date(2026, 8, 30), calendar: gregorian
        )

        let currentKey = SpendSummary.payPeriodKey(of: window.last!, calendar: gregorian)

        XCTAssertEqual(currentKey, date(2026, 9, 1))
    }

    /// Spend logged after the payday lands in the current period, which stays last in
    /// the series so the chart can mark it.
    func testByPayPeriodPutsPostPaydaySpendInTheCurrentPeriod() {
        let window = SpendSummary.payPeriodWindow(
            cycles: 3, payday: 25, now: date(2026, 8, 30), calendar: gregorian
        )
        let expenses = [Expense(amount: 50_000, date: date(2026, 8, 26))]

        let summary = SpendSummary.byPayPeriod(from: expenses, window: window, calendar: gregorian)

        XCTAssertEqual(summary.last?.date, date(2026, 9, 1))
        XCTAssertEqual(summary.last?.total, 50_000)
    }

    /// A period with no spend is still charted, so the run of periods stays continuous
    /// and the current one shows up even before its first expense.
    func testByPayPeriodZeroFillsQuietPeriods() {
        let window = SpendSummary.payPeriodWindow(
            cycles: 3, payday: 25, now: date(2026, 8, 30), calendar: gregorian
        )
        let expenses = [Expense(amount: 50_000, date: date(2026, 7, 1))]

        let summary = SpendSummary.byPayPeriod(from: expenses, window: window, calendar: gregorian)

        XCTAssertEqual(summary.map(\.date), [date(2026, 7, 1), date(2026, 8, 1), date(2026, 9, 1)])
        XCTAssertEqual(summary.map(\.total), [50_000, 0, 0])
    }

    /// Periods older than the first expense are dropped, so a new user does not get a
    /// year of blank bars ahead of their data.
    func testByPayPeriodDropsLeadingEmptyPeriods() {
        let window = SpendSummary.payPeriodWindow(
            cycles: 12, payday: 25, now: date(2026, 8, 30), calendar: gregorian
        )
        let expenses = [Expense(amount: 50_000, date: date(2026, 8, 26))]

        let summary = SpendSummary.byPayPeriod(from: expenses, window: window, calendar: gregorian)

        XCTAssertEqual(summary.map(\.date), [date(2026, 9, 1)])
    }

    /// Nothing spent anywhere in the window returns no series at all, so the card shows
    /// its empty state instead of a row of flat bars.
    func testByPayPeriodWithNoSpendReturnsEmpty() {
        let window = SpendSummary.payPeriodWindow(
            cycles: 12, payday: 25, now: date(2026, 8, 30), calendar: gregorian
        )
        let expenses = [Expense(amount: 50_000, date: date(2024, 1, 5))]

        let summary = SpendSummary.byPayPeriod(from: expenses, window: window, calendar: gregorian)

        XCTAssertTrue(summary.isEmpty)
    }

    // MARK: - Helpers

    private let gregorian = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        gregorian.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
