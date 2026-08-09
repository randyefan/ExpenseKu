//
//  PayCycleTests.swift
//  ExpenseKuTests
//
//  Covers the pure cycle-boundary math of PayCycle: the containing cycle, the
//  on-anchor edge, the roll back to the prior month, short-month clamping, prev/next
//  navigation (including the short-month "walk"), the end-month title, and the
//  payday=1 equivalence to a calendar month. A fixed gregorian calendar keeps the
//  arithmetic deterministic.
//

import XCTest
@testable import ExpenseKu

final class PayCycleTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    /// A mid-cycle date lands in the [payday, next payday) interval.
    func testContainingMidCycle() {
        let cycle = PayCycle.containing(date(2026, 8, 9), payday: 25, calendar: calendar)
        XCTAssertEqual(cycle.start, startOfDay(2026, 7, 25))
        XCTAssertEqual(cycle.end, startOfDay(2026, 8, 25))
    }

    /// On the anchor day, the cycle starts that day (start-of-day <= date).
    func testOnAnchorStartsToday() {
        let cycle = PayCycle.containing(date(2026, 8, 25, 8, 0), payday: 25, calendar: calendar)
        XCTAssertEqual(cycle.start, startOfDay(2026, 8, 25))
        XCTAssertEqual(cycle.end, startOfDay(2026, 9, 25))
    }

    /// Before the anchor, the cycle rolls back to the prior month's anchor.
    func testBeforeAnchorRollsBack() {
        let cycle = PayCycle.containing(date(2026, 8, 24), payday: 25, calendar: calendar)
        XCTAssertEqual(cycle.start, startOfDay(2026, 7, 25))
        XCTAssertEqual(cycle.end, startOfDay(2026, 8, 25))
    }

    /// The half-open interval excludes its upper bound and includes its start.
    func testContainsIsHalfOpen() {
        let cycle = PayCycle.containing(date(2026, 8, 9), payday: 25, calendar: calendar)
        XCTAssertTrue(cycle.contains(startOfDay(2026, 7, 25)))
        XCTAssertTrue(cycle.contains(date(2026, 8, 24, 23, 59)))
        XCTAssertFalse(cycle.contains(startOfDay(2026, 8, 25)))   // upper bound excluded
        XCTAssertFalse(cycle.contains(date(2026, 7, 24, 23, 59))) // just before start
    }

    /// A 31 anchor clamps to the last valid day of a short month.
    func testShortMonthClamp() {
        // A date in February with a 31 anchor: the cycle runs Jan 31 → Feb 28.
        let cycle = PayCycle.containing(date(2026, 2, 10), payday: 31, calendar: calendar)
        XCTAssertEqual(cycle.start, startOfDay(2026, 1, 31))
        XCTAssertEqual(cycle.end, startOfDay(2026, 2, 28))
    }

    /// Boundaries "walk" across a short month, then recover the anchor.
    func testShortMonthWalk() {
        let feb = PayCycle.containing(date(2026, 2, 10), payday: 31, calendar: calendar)
        let mar = feb.next(payday: 31, calendar: calendar)
        XCTAssertEqual(mar.start, startOfDay(2026, 2, 28))
        XCTAssertEqual(mar.end, startOfDay(2026, 3, 31))
    }

    /// Next then previous returns the original cycle.
    func testNextPreviousRoundTrip() {
        let cycle = PayCycle.containing(date(2026, 8, 9), payday: 25, calendar: calendar)
        let back = cycle.next(payday: 25, calendar: calendar).previous(payday: 25, calendar: calendar)
        XCTAssertEqual(back, cycle)
    }

    /// The title is the month the cycle ends in (Q4): 25 Jul → 24 Aug is "August 2026".
    func testTitleUsesEndMonth() {
        let cycle = PayCycle.containing(date(2026, 8, 9), payday: 25, calendar: calendar)
        XCTAssertEqual(cycle.title(calendar: calendar), "August 2026")
        XCTAssertEqual(cycle.lastDay(calendar: calendar), startOfDay(2026, 8, 24))
    }

    /// The range text renders as dd/MM/yyyy ~ dd/MM/yyyy over the closed span.
    func testRangeText() {
        let cycle = PayCycle.containing(date(2026, 8, 9), payday: 25, calendar: calendar)
        XCTAssertEqual(cycle.rangeText(calendar: calendar), "25/07/2026 ~ 24/08/2026")
    }

    /// payday = 1 makes a cycle identical to a calendar month.
    func testPaydayOneEqualsCalendarMonth() {
        let cycle = PayCycle.containing(date(2026, 8, 9), payday: 1, calendar: calendar)
        XCTAssertEqual(cycle.start, startOfDay(2026, 8, 1))
        XCTAssertEqual(cycle.end, startOfDay(2026, 9, 1))
    }

    // MARK: - Helpers

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func startOfDay(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.startOfDay(for: calendar.date(from: DateComponents(year: y, month: m, day: d))!)
    }
}
