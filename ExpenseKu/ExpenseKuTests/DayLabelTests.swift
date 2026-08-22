//
//  DayLabelTests.swift
//  ExpenseKuTests
//
//  Day naming for the Expenses tab. `title` heads a section; `phrase` goes inside a
//  sentence. They must not be interchangeable — "No expenses on Today" is the bug this
//  file exists to prevent. Relative days are pinned against a real "now" rather than a
//  fixed date, because that is what `isDateInToday` actually consults.
//

import XCTest
@testable import ExpenseKu

nonisolated final class DayLabelTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)

    // MARK: - title

    func testTitleForTodayIsRelative() {
        XCTAssertEqual(DayLabel.title(.now, calendar: calendar), "Today")
    }

    func testTitleForYesterdayIsRelative() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now)!
        XCTAssertEqual(DayLabel.title(yesterday, calendar: calendar), "Yesterday")
    }

    /// Anything older is spelled out, and carries weekday, day and month.
    func testTitleForOlderDayIsSpelledOut() {
        let old = calendar.date(from: DateComponents(year: 2026, month: 8, day: 6))!

        let title = DayLabel.title(old, calendar: calendar)

        XCTAssertNotEqual(title, "Today")
        XCTAssertNotEqual(title, "Yesterday")
        XCTAssertTrue(title.contains("August"), title)
        XCTAssertTrue(title.contains("6"), title)
    }

    // MARK: - phrase

    /// The whole reason this function exists: the phrase must read inside a sentence,
    /// so it is lowercase and takes no "on".
    func testPhraseForTodayHasNoPreposition() {
        XCTAssertEqual(DayLabel.phrase(.now, calendar: calendar), "today")
    }

    func testPhraseForYesterdayHasNoPreposition() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: .now)!
        XCTAssertEqual(DayLabel.phrase(yesterday, calendar: calendar), "yesterday")
    }

    /// A spelled-out day does take "on", because "No expenses Thu, 6 August" is wrong.
    func testPhraseForOlderDayTakesOn() {
        let old = calendar.date(from: DateComponents(year: 2026, month: 8, day: 6))!

        let phrase = DayLabel.phrase(old, calendar: calendar)

        XCTAssertTrue(phrase.hasPrefix("on "), phrase)
        XCTAssertTrue(phrase.contains("August"), phrase)
    }

    /// Sanity check on the pairing that actually ships: the sentence built from
    /// `phrase` never contains a capitalised relative day.
    func testSentenceReadsCorrectlyForRelativeDays() {
        XCTAssertEqual("No expenses \(DayLabel.phrase(.now, calendar: calendar))",
                       "No expenses today")
    }
}
