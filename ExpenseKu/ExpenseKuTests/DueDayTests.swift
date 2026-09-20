//
//  DueDayTests.swift
//  ExpenseKuTests
//
//  Resolving a day-of-month inside a cycle, and the badge it renders as (PRD §7.4).
//
//  Two things get written wrong by hand. A cycle spans two calendar months, so which
//  month a due day belongs to depends on the payday anchor. And 29–31 must clamp to
//  the end of a short month — through PayCycle's clamp, not a second copy of it.
//

import XCTest
@testable import ExpenseKu

nonisolated final class DueDayTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d)) ?? .distantPast
    }

    private func cycle(_ y: Int, _ m: Int, _ d: Int, payday: Int) -> PayCycle {
        PayCycle.containing(date(y, m, d), payday: payday, calendar: calendar)
    }

    /// With payday 1 a cycle is one calendar month, so every day resolves in it.
    func testPaydayOneResolvesWithinTheMonth() {
        let september = cycle(2026, 9, 10, payday: 1)
        XCTAssertEqual(DueDay.date(day: 20, in: september, calendar: calendar), date(2026, 9, 20))
    }

    /// With payday 25 the cycle spans two months, and a low day belongs to the
    /// *second* one — the commonest way a hand-rolled version gets this wrong.
    func testASpanningCycleResolvesIntoTheRightMonth() {
        let cycle = self.cycle(2026, 7, 26, payday: 25)   // 25 Jul → 24 Aug
        XCTAssertEqual(DueDay.date(day: 20, in: cycle, calendar: calendar), date(2026, 8, 20))
        XCTAssertEqual(DueDay.date(day: 28, in: cycle, calendar: calendar), date(2026, 7, 28))
    }

    /// 29–31 clamp to the last valid day, reusing the Payday anchor's own clamp.
    func testShortMonthsClamp() {
        let february = cycle(2026, 2, 10, payday: 1)      // 2026 is not a leap year
        XCTAssertEqual(DueDay.date(day: 31, in: february, calendar: calendar), date(2026, 2, 28))
        let leap = cycle(2024, 2, 10, payday: 1)
        XCTAssertEqual(DueDay.date(day: 31, in: leap, calendar: calendar), date(2024, 2, 29))
    }

    /// A day the cycle genuinely does not contain resolves to nothing rather than to
    /// a date outside it.
    ///
    /// This takes a walking cycle to reach at all: with an ordinary anchor every day
    /// 1–31 lands in one of the cycle's two months. A payday-31 cycle running
    /// 31 Jan → 28 Feb is the case — day 29 clamps to 28 February, which is the
    /// cycle's exclusive end and so outside it, and 29 January is before its start.
    func testADayOutsideTheCycleIsNil() {
        let walking = cycle(2026, 2, 1, payday: 31)       // 31 Jan → 28 Feb
        XCTAssertEqual(walking.start, date(2026, 1, 31))
        XCTAssertEqual(walking.end, date(2026, 2, 28))
        XCTAssertNil(DueDay.date(day: 29, in: walking, calendar: calendar))
    }

    /// The everyday case that looks like the one above and is not: with payday 15, a
    /// day below the anchor resolves into the cycle's second month, not to nil.
    func testALowDayResolvesIntoTheSecondMonth() {
        let cycle = self.cycle(2026, 1, 20, payday: 15)   // 15 Jan → 15 Feb
        XCTAssertEqual(DueDay.date(day: 14, in: cycle, calendar: calendar), date(2026, 2, 14))
    }

    /// The badge is absolute by default: "Due 25" is what carry-over stores and what
    /// the owner recognises.
    func testTheBadgeIsAbsoluteWhenTheDayIsFarOff() {
        let september = cycle(2026, 9, 1, payday: 1)
        let label = DueDay.label(day: 25, in: september, today: date(2026, 9, 5), calendar: calendar)
        XCTAssertEqual(label.text, "Due 25")
        XCTAssertFalse(label.isSoon)
    }

    /// It turns relative within three days, and only then.
    func testTheBadgeTurnsRelativeWithinThreeDays() {
        let september = cycle(2026, 9, 1, payday: 1)
        let soon = DueDay.label(day: 25, in: september, today: date(2026, 9, 22), calendar: calendar)
        XCTAssertTrue(soon.isSoon)
        XCTAssertTrue(soon.text.contains("3"), soon.text)

        let today = DueDay.label(day: 25, in: september, today: date(2026, 9, 25), calendar: calendar)
        XCTAssertEqual(today.text, "due today")
        XCTAssertTrue(today.isSoon)

        let stillFar = DueDay.label(day: 25, in: september, today: date(2026, 9, 21), calendar: calendar)
        XCTAssertFalse(stillFar.isSoon)
    }

    /// **Never relative in a cycle that has not started.** A countdown to a day inside
    /// next month's plan is meaningless — and the plan is built precisely there.
    func testTheBadgeStaysAbsoluteInAFutureCycle() {
        let october = cycle(2026, 10, 1, payday: 1)
        let label = DueDay.label(day: 2, in: october, today: date(2026, 9, 30), calendar: calendar)
        XCTAssertEqual(label.text, "Due 2")
        XCTAssertFalse(label.isSoon)
    }

    /// A day already past does not read as "due in −2 days".
    func testAPastDayReadsAbsolute() {
        let september = cycle(2026, 9, 1, payday: 1)
        let label = DueDay.label(day: 5, in: september, today: date(2026, 9, 20), calendar: calendar)
        XCTAssertEqual(label.text, "Due 5")
        XCTAssertFalse(label.isSoon)
    }
}
