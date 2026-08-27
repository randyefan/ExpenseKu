//
//  SearchDateLabelTests.swift
//  ExpenseKuTests
//
//  Behaviour oracle for the date shown on a search result row. Results span
//  years, so the label must carry a year exactly when the expense is not from
//  the current one. Assertions check for the *presence* of the year rather than
//  an exact string, so the suite doesn't break under a different locale.
//

import XCTest
@testable import ExpenseKu

nonisolated final class SearchDateLabelTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    /// Within the current year the label carries no year — just day + month.
    func testSameYearOmitsYear() {
        let label = SearchDateLabel.text(date(2026, 9, 2), now: date(2026, 8, 28), calendar: calendar)

        XCTAssertTrue(label.contains("2"), "expected the day number in \(label)")
        XCTAssertFalse(label.contains("26"), "same-year label should carry no year: \(label)")
    }

    /// An expense from another year carries a two-digit year.
    func testOtherYearIncludesYear() {
        let label = SearchDateLabel.text(date(2025, 3, 3), now: date(2026, 8, 28), calendar: calendar)

        XCTAssertTrue(label.contains("25"), "expected a two-digit year in \(label)")
    }

    /// The boundary is the calendar year, not a rolling twelve months: 31 Dec and
    /// the 1 Jan a day later are formatted differently.
    func testYearBoundaryFlipsTheFormat() {
        let now = date(2026, 1, 15)

        let december = SearchDateLabel.text(date(2025, 12, 31), now: now, calendar: calendar)
        let january = SearchDateLabel.text(date(2026, 1, 1), now: now, calendar: calendar)

        XCTAssertTrue(december.contains("25"), "expected a year on \(december)")
        XCTAssertFalse(january.contains("26"), "expected no year on \(january)")
    }

    /// Today renders as a date like any other row — never "Today". A search
    /// result list mixing "Today" with "3 Mar 25" reads as two different things.
    func testTodayIsStillADate() {
        let today = date(2026, 8, 28)

        let label = SearchDateLabel.text(today, now: today, calendar: calendar)

        XCTAssertFalse(label.localizedCaseInsensitiveContains("today"))
        XCTAssertTrue(label.contains("28"))
    }

    // MARK: - Helpers

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }
}
