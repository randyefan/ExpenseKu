//
//  CyclePagingTests.swift
//  ExpenseKuTests
//
//  The ‹ › arrows on the Expenses tab. Back is enabled only when data exists before
//  the visible cycle; forward stops at the present cycle (Q7). Both are boundary
//  checks, so the cases that matter are the ones sitting exactly on the boundary.
//

import XCTest
@testable import ExpenseKu

nonisolated final class CyclePagingTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    private var cycle: PayCycle {
        PayCycle.containing(date(2026, 8, 10), payday: 1, calendar: calendar)
    }

    // MARK: - Back

    /// An empty store has nothing to page back to.
    func testCannotGoBackWithNoExpenses() {
        XCTAssertFalse(CyclePaging.canGoBack(from: cycle, oldestExpense: nil))
    }

    /// Data in an earlier cycle enables the back arrow.
    func testCanGoBackWithOlderData() {
        XCTAssertTrue(CyclePaging.canGoBack(from: cycle, oldestExpense: date(2026, 7, 15)))
    }

    /// Data inside the visible cycle is not "older" — there is still nowhere to go.
    func testCannotGoBackWhenOldestIsInsideCycle() {
        XCTAssertFalse(CyclePaging.canGoBack(from: cycle, oldestExpense: date(2026, 8, 5)))
    }

    /// The oldest expense sitting exactly on `cycle.start` belongs to this cycle,
    /// so it must not enable the arrow.
    func testCannotGoBackWhenOldestIsExactlyCycleStart() {
        XCTAssertFalse(CyclePaging.canGoBack(from: cycle, oldestExpense: cycle.start))
    }

    /// One second before the boundary is a different cycle, and does enable it.
    func testCanGoBackOneSecondBeforeCycleStart() {
        let justBefore = cycle.start.addingTimeInterval(-1)
        XCTAssertTrue(CyclePaging.canGoBack(from: cycle, oldestExpense: justBefore))
    }

    // MARK: - Forward

    /// A cycle that has already ended can be paged forward out of.
    func testCanGoForwardFromAPastCycle() {
        XCTAssertTrue(CyclePaging.canGoForward(from: cycle, now: date(2026, 10, 1)))
    }

    /// The cycle containing "now" is the last one — forward is disabled.
    func testCannotGoForwardFromTheCurrentCycle() {
        XCTAssertFalse(CyclePaging.canGoForward(from: cycle, now: date(2026, 8, 10)))
    }

    /// `end` is exclusive: the instant the cycle ends, the next one has begun and
    /// forward is allowed.
    func testCanGoForwardExactlyAtCycleEnd() {
        XCTAssertTrue(CyclePaging.canGoForward(from: cycle, now: cycle.end))
    }

    /// One second earlier is still inside the cycle.
    func testCannotGoForwardOneSecondBeforeCycleEnd() {
        XCTAssertFalse(CyclePaging.canGoForward(from: cycle, now: cycle.end.addingTimeInterval(-1)))
    }

    // MARK: - Helpers

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }
}
