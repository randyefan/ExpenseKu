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

final class ExpenseDayGroupingTests: XCTestCase {

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

    // MARK: - Helpers

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func startOfDay(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.startOfDay(for: calendar.date(from: DateComponents(year: y, month: m, day: d))!)
    }
}
