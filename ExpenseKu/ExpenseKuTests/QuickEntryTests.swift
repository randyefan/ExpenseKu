//
//  QuickEntryTests.swift
//  ExpenseKuTests
//
//  docs/prd/quick-entry-form.md §4: the date chips and the one-tap picks, with the PRD's
//  sample — now is Sat 7 Nov 2026, 20.15.
//

import XCTest
@testable import ExpenseKu

nonisolated final class QuickEntryTests: XCTestCase {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .gmt
        return calendar
    }()

    private func at(_ day: Int, _ hour: Int, _ minute: Int, second: Int = 0, month: Int = 11) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour, minute: minute, second: second)) ?? .distantPast
    }

    private var now: Date { at(7, 20, 15, second: 30) }

    // MARK: - §4.1 When

    func testNowIsTheMomentOfTheTap() {
        XCTAssertEqual(WhenShortcut.now.date(from: now, calendar: calendar), now)
    }

    func testHoursAgoCountBackFromNow() {
        XCTAssertEqual(WhenShortcut.oneHourAgo.date(from: now, calendar: calendar), at(7, 19, 15, second: 30))
        XCTAssertEqual(WhenShortcut.threeHoursAgo.date(from: now, calendar: calendar), at(7, 17, 15, second: 30))
    }

    func testYesterdayKeepsTheClockTime() {
        XCTAssertEqual(WhenShortcut.yesterday.date(from: now, calendar: calendar), at(6, 20, 15, second: 30))
    }

    func testThreeHoursAgoAfterMidnightLandsOnTheDayBefore() {
        let earlyMorning = at(8, 1, 0)
        XCTAssertEqual(WhenShortcut.threeHoursAgo.date(from: earlyMorning, calendar: calendar), at(7, 22, 0))
    }

    func testYesterdayOnTheFirstCrossesTheMonth() {
        XCTAssertEqual(WhenShortcut.yesterday.date(from: at(1, 9, 0), calendar: calendar), at(31, 9, 0, month: 10))
    }

    func testTappedChipStaysLitAfterTheMinutePasses() {
        let set = WhenShortcut.oneHourAgo.date(from: now, calendar: calendar)
        let later = now.addingTimeInterval(5 * 60)
        let selection = WhenSelection.resolve(date: set, tap: WhenTap(shortcut: .oneHourAgo, date: set),
                                              now: later, calendar: calendar)
        XCTAssertEqual(selection, .shortcut(.oneHourAgo))
    }

    func testChangingTheTimeByHandUnlightsTheTappedChip() {
        let set = WhenShortcut.oneHourAgo.date(from: now, calendar: calendar)
        let edited = set.addingTimeInterval(-10 * 60)
        let selection = WhenSelection.resolve(date: edited, tap: WhenTap(shortcut: .oneHourAgo, date: set),
                                              now: now, calendar: calendar)
        XCTAssertEqual(selection, .custom(edited))
    }

    func testAnUntappedDateMatchesAChipToTheMinute() {
        XCTAssertEqual(WhenSelection.resolve(date: at(7, 17, 15), tap: nil, now: now, calendar: calendar),
                       .shortcut(.threeHoursAgo))
        XCTAssertEqual(WhenSelection.resolve(date: at(6, 20, 15, second: 2), tap: nil, now: now, calendar: calendar),
                       .shortcut(.yesterday))
    }

    func testAStoredDateNoChipNamesIsItsOwnChip() {
        let stored = at(3, 12, 40)
        XCTAssertEqual(WhenSelection.resolve(date: stored, tap: nil, now: now, calendar: calendar), .custom(stored))
    }

    // MARK: - §4.2 Category

    private func candidates(_ names: [String]) -> [QuickPicks.Candidate<String>] {
        names.map { QuickPicks.Candidate(id: $0, name: $0) }
    }

    private func uses(_ ids: [String], on date: Date) -> [QuickPicks.Use<String>] {
        ids.map { QuickPicks.Use(ids: [$0], date: date) }
    }

    private var since: Date { QuickPicks.windowStart(now: now, calendar: calendar) }

    func testMostUsedFirstThenByName() {
        let ranked = QuickPicks.ranked(candidates(["Kopi", "Bensin", "Makan", "Parkir"]),
                                       uses: uses(["Makan", "Makan", "Kopi", "Parkir"], on: at(5, 12, 0)),
                                       since: since)
        XCTAssertEqual(ranked, ["Makan", "Kopi", "Parkir", "Bensin"])
    }

    func testUsesOlderThanNinetyDaysDoNotCount() {
        let old = calendar.date(byAdding: .day, value: -91, to: now) ?? now
        let ranked = QuickPicks.ranked(candidates(["Hotel", "Kopi"]),
                                       uses: uses(["Hotel", "Hotel"], on: old) + uses(["Kopi"], on: at(6, 8, 0)),
                                       since: since)
        XCTAssertEqual(ranked, ["Kopi", "Hotel"])
    }

    func testNamesTieLikeTheFinderDoes() {
        let ranked = QuickPicks.ranked(candidates(["item 10", "Item 2", "apel"]), uses: [], since: since)
        XCTAssertEqual(ranked, ["apel", "Item 2", "item 10"])
    }

    func testTheGridHoldsSevenTiles() {
        let ranking = (1...9).map { "C\($0)" }
        XCTAssertEqual(QuickPicks.categoryTiles(ranking: ranking, pulled: nil), Array(ranking.prefix(7)))
    }

    func testFewerThanSevenCategoriesShowsThemAll() {
        XCTAssertEqual(QuickPicks.categoryTiles(ranking: ["Makan", "Kopi"], pulled: nil), ["Makan", "Kopi"])
    }

    func testACategoryFromAllTakesTheFirstTileAndTheSeventhDropsOut() {
        let ranking = (1...9).map { "C\($0)" }
        XCTAssertEqual(QuickPicks.categoryTiles(ranking: ranking, pulled: "Laundry"),
                       ["Laundry", "C1", "C2", "C3", "C4", "C5", "C6"])
    }

    func testAPulledCategoryAlreadyInTheGridIsNotDoubled() {
        let ranking = (1...9).map { "C\($0)" }
        XCTAssertEqual(QuickPicks.categoryTiles(ranking: ranking, pulled: "C3"),
                       ["C3", "C1", "C2", "C4", "C5", "C6", "C7"])
    }

    // MARK: - §4.4 People

    func testOnlyPeopleTaggedInTheWindowRideTheRail() {
        let used = QuickPicks.used(candidates(["Budi", "Fadil", "Tarisa"]),
                                   uses: uses(["Tarisa", "Tarisa", "Fadil"], on: at(4, 19, 0)),
                                   since: since)
        XCTAssertEqual(used, ["Tarisa", "Fadil"])
    }

    func testMeLeadsThenJoinedThenMostTagged() {
        let rail = QuickPicks.peopleRail(me: "Me", ranking: ["Tarisa", "Fadil"], joined: ["Ibu"])
        XCTAssertEqual(rail, ["Me", "Ibu", "Tarisa", "Fadil"])
    }

    func testTheRailCarriesSixMostTaggedBesidesMeAndJoined() {
        let ranking = (1...9).map { "P\($0)" }
        let rail = QuickPicks.peopleRail(me: "Me", ranking: ranking, joined: ["Ibu"])
        XCTAssertEqual(rail, ["Me", "Ibu", "P1", "P2", "P3", "P4", "P5", "P6"])
    }

    func testAJoinedPersonAlreadyOnTheRailIsNotDoubled() {
        let rail = QuickPicks.peopleRail(me: "Me", ranking: ["Tarisa", "Fadil"], joined: ["Tarisa", "Me"])
        XCTAssertEqual(rail, ["Me", "Tarisa", "Fadil"])
    }

    // MARK: - §4.3 Account

    func testANewExpenseStartsOnTheLastHandLoggedAccount() {
        let account = QuickPicks.defaultAccount(latestFirst: [
            (account: "BCA", isFromPlan: true),
            (account: "Jago", isFromPlan: false),
            (account: "Cash", isFromPlan: false),
        ])
        XCTAssertEqual(account, "Jago")
    }

    func testTheLastExpenseWithoutAnAccountMeansNone() {
        let account = QuickPicks.defaultAccount(latestFirst: [(account: nil, isFromPlan: false),
                                                              (account: "Jago", isFromPlan: false)])
        XCTAssertNil(account)
    }

    func testNoExpensesMeansNone() {
        XCTAssertNil(QuickPicks.defaultAccount(latestFirst: [(account: String?, isFromPlan: Bool)]()))
    }
}
