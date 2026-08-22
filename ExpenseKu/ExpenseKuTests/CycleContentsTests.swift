//
//  CycleContentsTests.swift
//  ExpenseKuTests
//
//  What the Expenses tab derives from a cycle. The filter, the total and the day
//  grouping all come from one pass, so these also pin that they agree with each other:
//  an expense counted in the total is an expense that appears in a day group.
//

import XCTest
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class CycleContentsTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private var augustCycle: PayCycle {
        PayCycle.containing(date(2026, 8, 10), payday: 1, calendar: calendar)
    }

    /// Expenses outside the cycle are excluded from every derived value.
    func testExcludesExpensesOutsideTheCycle() {
        let inside = Expense(amount: 50_000, date: date(2026, 8, 5))
        let before = Expense(amount: 30_000, date: date(2026, 7, 20))
        let after = Expense(amount: 20_000, date: date(2026, 9, 3))

        let contents = CycleContents(
            cycle: augustCycle, allExpenses: [inside, before, after], calendar: calendar)

        XCTAssertEqual(contents.expenses.count, 1)
        XCTAssertEqual(contents.total, 50_000)
        XCTAssertEqual(contents.dayGroups.count, 1)
    }

    /// An empty cycle totals zero rather than crashing or returning nil.
    func testEmptyCycleTotalsZero() {
        let contents = CycleContents(
            cycle: augustCycle, allExpenses: [], calendar: calendar)

        XCTAssertTrue(contents.isEmpty)
        XCTAssertEqual(contents.total, 0)
        XCTAssertTrue(contents.dayGroups.isEmpty)
    }

    /// A cycle with data elsewhere is still empty here — the distinction the two
    /// different empty states on the Expenses tab depend on.
    func testCycleIsEmptyEvenWhenOtherCyclesHaveData() {
        let elsewhere = Expense(amount: 10_000, date: date(2026, 5, 1))

        let contents = CycleContents(
            cycle: augustCycle, allExpenses: [elsewhere], calendar: calendar)

        XCTAssertTrue(contents.isEmpty)
    }

    /// The total is the sum of the day-group totals: one filter feeds both, so they
    /// can never disagree.
    func testTotalMatchesSumOfDayGroups() {
        let expenses = [
            Expense(amount: 120_000, date: date(2026, 8, 2, 20)),
            Expense(amount: 25_000, date: date(2026, 8, 2, 8)),
            Expense(amount: 45_000, date: date(2026, 8, 5, 13)),
        ]

        let contents = CycleContents(
            cycle: augustCycle, allExpenses: expenses, calendar: calendar)

        let groupSum = contents.dayGroups.reduce(Decimal(0)) { $0 + $1.total }
        XCTAssertEqual(contents.total, 190_000)
        XCTAssertEqual(contents.total, groupSum)
    }

    /// Expenses on the same day collapse into one group, newest time first.
    func testSameDayExpensesShareOneGroup() {
        let morning = Expense(amount: 25_000, date: date(2026, 8, 2, 8), note: "morning")
        let evening = Expense(amount: 120_000, date: date(2026, 8, 2, 20), note: "evening")

        let contents = CycleContents(
            cycle: augustCycle, allExpenses: [morning, evening], calendar: calendar)

        XCTAssertEqual(contents.dayGroups.count, 1)
        XCTAssertEqual(contents.dayGroups[0].expenses.map(\.note), ["evening", "morning"])
    }

    /// An expense exactly on `cycle.start` is inside; `cycle.end` is exclusive.
    func testCycleBoundariesAreHalfOpen() {
        let atStart = Expense(amount: 1, date: augustCycle.start)
        let atEnd = Expense(amount: 1, date: augustCycle.end)

        let contents = CycleContents(
            cycle: augustCycle, allExpenses: [atStart, atEnd], calendar: calendar)

        XCTAssertEqual(contents.expenses.count, 1)
        XCTAssertEqual(contents.total, 1)
    }

    // MARK: - group(for:)

    /// A day with expenses resolves to its group.
    func testGroupForDayWithExpenses() {
        let expense = Expense(amount: 45_000, date: date(2026, 8, 5, 13))
        let contents = CycleContents(
            cycle: augustCycle, allExpenses: [expense], calendar: calendar)

        let day = calendar.startOfDay(for: date(2026, 8, 5))
        XCTAssertEqual(contents.group(for: day)?.total, 45_000)
    }

    /// A day with none resolves to nil, which is what drives the per-day empty state.
    func testGroupForEmptyDayIsNil() {
        let expense = Expense(amount: 45_000, date: date(2026, 8, 5, 13))
        let contents = CycleContents(
            cycle: augustCycle, allExpenses: [expense], calendar: calendar)

        let otherDay = calendar.startOfDay(for: date(2026, 8, 6))
        XCTAssertNil(contents.group(for: otherDay))
    }

    // MARK: - Helpers

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }
}
