//
//  ExpenseDayGroupingTests.swift
//  ExpenseKuTests
//
//  Behaviour oracle for the expense-time feature: the expenses list groups by
//  calendar day (most recent first) and orders same-day expenses by the time set
//  on each expense (latest first). A fixed gregorian calendar keeps it deterministic.
//

import XCTest
@testable import ExpenseKu

nonisolated final class ExpenseDayGroupingTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    /// Two expenses on the same day come back newest-time first.
    func testWithinDaySortedByTimeDescending() {
        let morning = Expense(amount: 25_000, date: date(2026, 8, 2, 8, 15), note: "morning")
        let evening = Expense(amount: 120_000, date: date(2026, 8, 2, 20, 30), note: "evening")

        let groups = expenseDayGroups([morning, evening], calendar: calendar)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].expenses.map(\.note), ["evening", "morning"])
    }

    /// Groups are ordered most-recent-day first.
    func testDaysSortedDescending() {
        let older = Expense(amount: 1, date: date(2026, 7, 20, 9, 0), note: "jul20")
        let newer = Expense(amount: 1, date: date(2026, 8, 6, 9, 0), note: "aug6")
        let middle = Expense(amount: 1, date: date(2026, 8, 2, 9, 0), note: "aug2")

        let groups = expenseDayGroups([older, newer, middle], calendar: calendar)

        XCTAssertEqual(groups.map { $0.expenses.first?.note }, ["aug6", "aug2", "jul20"])
    }

    /// Identical timestamps don't drop or duplicate rows.
    func testSameTimestampPreservesCount() {
        let a = Expense(amount: 1, date: date(2026, 8, 2, 12, 0), note: "a")
        let b = Expense(amount: 1, date: date(2026, 8, 2, 12, 0), note: "b")

        let groups = expenseDayGroups([a, b], calendar: calendar)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].expenses.count, 2)
    }

    /// Times across one calendar day (00:05 … 23:55) land in a single group.
    func testGroupingUsesStartOfDay() {
        let early = Expense(amount: 1, date: date(2026, 8, 2, 0, 5), note: "early")
        let late = Expense(amount: 1, date: date(2026, 8, 2, 23, 55), note: "late")

        let groups = expenseDayGroups([early, late], calendar: calendar)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].day, startOfDay(2026, 8, 2))
        XCTAssertEqual(groups[0].expenses.map(\.note), ["late", "early"])
    }

    // MARK: - Per-day total (daily-total feature)

    /// A day's total is the sum of its expense amounts.
    func testDayTotalSumsAmounts() {
        let a = Expense(amount: 25_000, date: date(2026, 8, 2, 8, 15), note: "a")
        let b = Expense(amount: 120_000, date: date(2026, 8, 2, 20, 30), note: "b")

        let groups = expenseDayGroups([a, b], calendar: calendar)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].total, 145_000)
    }

    /// Each day reports its own total, not a running or global sum.
    func testDayTotalsPerGroupAreIndependent() {
        let aug2a = Expense(amount: 25_000, date: date(2026, 8, 2, 8, 0), note: "aug2a")
        let aug2b = Expense(amount: 120_000, date: date(2026, 8, 2, 20, 0), note: "aug2b")
        let aug6 = Expense(amount: 30_000, date: date(2026, 8, 6, 9, 0), note: "aug6")

        let groups = expenseDayGroups([aug2a, aug2b, aug6], calendar: calendar)

        // groups[0] is the most recent day (Aug 6), groups[1] is Aug 2.
        XCTAssertEqual(groups.map(\.total), [30_000, 145_000])
    }

    /// A single-expense day totals to exactly that expense's amount.
    func testSingleExpenseDayTotalEqualsItsAmount() {
        let only = Expense(amount: 45_000, date: date(2026, 8, 2, 12, 0), note: "only")

        let groups = expenseDayGroups([only], calendar: calendar)

        XCTAssertEqual(groups[0].total, 45_000)
    }

    // MARK: - Helpers

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func startOfDay(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.startOfDay(for: calendar.date(from: DateComponents(year: y, month: m, day: d))!)
    }
}
