//
//  DateRangeFilterTests.swift
//  ExpenseKuTests
//
//  Covers the pure "This pay period" math of DateRangeFilter.range(payday:):
//  anchor clamping, the roll to the prior month, and the end-at-now boundary.
//  A fixed gregorian calendar keeps the arithmetic deterministic.
//

import XCTest
@testable import ExpenseKu

nonisolated final class DateRangeFilterTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    /// payday = 1 makes the pay period identical to "This month".
    func testPaydayOneEqualsThisMonthStart() {
        let now = date(2026, 6, 15, 9, 30)
        let payPeriod = DateRangeFilter.payPeriod.range(now: now, calendar: calendar, payday: 1)
        let thisMonth = DateRangeFilter.thisMonth.range(now: now, calendar: calendar)
        XCTAssertEqual(payPeriod?.lowerBound, thisMonth?.lowerBound)
    }

    /// After the payday in the current month, the period starts on that payday.
    func testAfterPaydayStartsThisMonth() {
        let now = date(2026, 6, 20, 12, 0)
        let range = DateRangeFilter.payPeriod.range(now: now, calendar: calendar, payday: 5)
        XCTAssertEqual(range?.lowerBound, startOfDay(2026, 6, 5))
    }

    /// Before the payday, the period rolls back to the prior month's payday.
    func testBeforePaydayRollsToPriorMonth() {
        let now = date(2026, 6, 3, 12, 0)
        let range = DateRangeFilter.payPeriod.range(now: now, calendar: calendar, payday: 25)
        XCTAssertEqual(range?.lowerBound, startOfDay(2026, 5, 25))
    }

    /// A payday of 31 clamps to the last valid day of a short month (Feb 2026 = 28).
    func testShortMonthClampsToLastDay() {
        let now = date(2026, 3, 10, 12, 0)          // before the 31st → roll to February
        let range = DateRangeFilter.payPeriod.range(now: now, calendar: calendar, payday: 31)
        XCTAssertEqual(range?.lowerBound, startOfDay(2026, 2, 28))
    }

    /// On the payday itself, the period starts today (start-of-day <= now).
    func testOnPaydayStartsToday() {
        let now = date(2026, 6, 25, 8, 0)
        let range = DateRangeFilter.payPeriod.range(now: now, calendar: calendar, payday: 25)
        XCTAssertEqual(range?.lowerBound, startOfDay(2026, 6, 25))
    }

    /// The period always ends at `now`, matching the other "this X" presets.
    func testEndsAtNow() {
        let now = date(2026, 6, 20, 14, 45)
        let range = DateRangeFilter.payPeriod.range(now: now, calendar: calendar, payday: 5)
        XCTAssertEqual(range?.upperBound, now)
    }

    // MARK: - Helpers

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func startOfDay(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.startOfDay(for: calendar.date(from: DateComponents(year: y, month: m, day: d))!)
    }
}
