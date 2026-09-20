//
//  CyclePagingTests.swift
//  ExpenseKuTests
//
//  When the ‹ › cycle arrows are enabled.
//
//  This file used to pin the opposite rule for the forward arrow: it stopped at the
//  present cycle, so paging never landed on an empty future one (Q7). The cycle plan
//  reverses that — the next cycle is precisely where planning happens (PRD §7.1,
//  decision 15) — and the tests are rewritten rather than deleted, so a future reader
//  finds out the old behaviour went deliberately.
//
//  Back learned about plans at the same time: a cycle holding only a plan and no
//  expenses has to stay reachable, which is exactly what a plan built a cycle ahead is.
//

import XCTest
@testable import ExpenseKu

nonisolated final class CyclePagingTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d)) ?? .distantPast
    }

    private func cycle(_ y: Int, _ m: Int, _ d: Int, payday: Int = 1) -> PayCycle {
        PayCycle.containing(date(y, m, d), payday: payday, calendar: calendar)
    }

    // MARK: - Back

    /// An empty store has nowhere to go back to.
    func testCannotGoBackWithNothingAtAll() {
        XCTAssertFalse(CyclePaging.canGoBack(from: cycle(2026, 8, 10),
                                             oldestExpense: nil, oldestPlanStart: nil))
    }

    /// An older expense enables it.
    func testAnOlderExpenseEnablesBack() {
        XCTAssertTrue(CyclePaging.canGoBack(from: cycle(2026, 8, 10),
                                            oldestExpense: date(2026, 7, 20),
                                            oldestPlanStart: nil))
    }

    /// An expense inside the visible cycle is not older than it.
    func testAnExpenseInThisCycleDoesNotEnableBack() {
        XCTAssertFalse(CyclePaging.canGoBack(from: cycle(2026, 8, 10),
                                             oldestExpense: date(2026, 8, 3),
                                             oldestPlanStart: nil))
    }

    /// The boundary is exclusive: an expense exactly at the cycle's start belongs to
    /// this cycle, not to an earlier one.
    func testAnExpenseExactlyAtTheStartDoesNotEnableBack() {
        let august = cycle(2026, 8, 10)
        XCTAssertFalse(CyclePaging.canGoBack(from: august,
                                             oldestExpense: august.start,
                                             oldestPlanStart: nil))
    }

    /// **A cycle holding only a plan stays reachable.** Without this a plan built
    /// before its cycle became unreachable the moment the owner paged past it — the
    /// very cycle they built it for.
    func testAPlanAloneEnablesBack() {
        XCTAssertTrue(CyclePaging.canGoBack(from: cycle(2026, 8, 10),
                                            oldestExpense: nil,
                                            oldestPlanStart: date(2026, 7, 1)))
    }

    /// Whichever is older wins, in both directions.
    func testTheOlderOfTheTwoWins() {
        let august = cycle(2026, 8, 10)
        XCTAssertTrue(CyclePaging.canGoBack(from: august,
                                            oldestExpense: date(2026, 8, 3),
                                            oldestPlanStart: date(2026, 6, 1)))
        XCTAssertTrue(CyclePaging.canGoBack(from: august,
                                            oldestExpense: date(2026, 6, 1),
                                            oldestPlanStart: date(2026, 8, 1)))
    }

    /// A plan for the visible cycle is not a reason to go back.
    func testAPlanForThisCycleDoesNotEnableBack() {
        let august = cycle(2026, 8, 10)
        XCTAssertFalse(CyclePaging.canGoBack(from: august,
                                             oldestExpense: nil,
                                             oldestPlanStart: august.start))
    }

    // MARK: - Forward

    /// **Forward always opens.** It used to stop at the present cycle; planning
    /// happens in the cycle that has not started yet, and an arrow that enables and
    /// disables depending on which lens is selected reads as a bug — so it opens in
    /// every lens, and List and Month show their existing empty state there.
    func testForwardIsAlwaysEnabled() {
        XCTAssertTrue(CyclePaging.canGoForward(from: cycle(2026, 8, 10)))
        XCTAssertTrue(CyclePaging.canGoForward(from: cycle(2026, 1, 1)))
        XCTAssertTrue(CyclePaging.canGoForward(from: cycle(2030, 12, 31)))
    }
}
