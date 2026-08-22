//
//  CycleCalendarTests.swift
//  ExpenseKuTests
//
//  Behaviour oracle for the expense-calendar feature: a pay cycle laid out as whole
//  weeks, each day carrying its own spend, filler days carrying none. A fixed
//  gregorian calendar keeps it deterministic.
//

import XCTest
@testable import ExpenseKu

nonisolated final class CycleCalendarTests: XCTestCase {

    /// Sunday-first, matching the default US gregorian calendar.
    private let calendar = Calendar(identifier: .gregorian)

    /// The seeded cycle: 25/07/2026 ~ 24/08/2026 (payday 25).
    private var augustCycle: PayCycle {
        PayCycle.containing(date(2026, 8, 16, 12, 0), payday: 25, calendar: calendar)
    }

    /// The fixtures from DebugLaunch.seedIfNeeded, including the 20 Jul expense that
    /// falls *outside* the August cycle.
    private var seeded: [Expense] {
        [
            Expense(amount: 120_000, date: date(2026, 8, 2, 20, 30), note: "Dinner"),
            Expense(amount: 25_000, date: date(2026, 8, 2, 8, 15), note: "Morning coffee"),
            Expense(amount: 45_000, date: date(2026, 8, 5, 13, 5), note: "Lunch"),
            Expense(amount: 30_000, date: date(2026, 8, 6, 18, 40), note: "Grab home"),
            Expense(amount: 25_000, date: date(2026, 7, 20, 9, 25), note: "Latte"),
            Expense(amount: 80_000, date: date(2026, 7, 28, 19, 0), note: "Ojek + makan"),
        ]
    }

    // MARK: - Grid shape

    /// Every row is a full week, and the grid opens on the start-of-week containing
    /// the cycle's first day (25 Jul 2026 is a Saturday ⇒ the row starts Sun 19 Jul).
    func testGridIsWholeWeeksStartingOnStartOfWeek() {
        let grid = cycleCalendar(for: augustCycle, expenses: [], calendar: calendar)

        XCTAssertTrue(grid.weeks.allSatisfy { $0.count == 7 })
        XCTAssertEqual(grid.weeks.first?.first?.date, startOfDay(2026, 7, 19))
        XCTAssertEqual(grid.weeks.last?.last?.date, startOfDay(2026, 8, 29))
    }

    /// Each day the cycle owns appears exactly once, marked in-cycle.
    func testEveryCycleDayAppearsExactlyOnceAndIsInCycle() {
        let cycle = augustCycle
        let grid = cycleCalendar(for: cycle, expenses: [], calendar: calendar)

        let owned = grid.cycleDays.map(\.date)
        XCTAssertEqual(owned.count, Set(owned).count, "a day is duplicated in the grid")
        // 25 Jul … 24 Aug inclusive = 31 days.
        XCTAssertEqual(owned.count, 31)
        XCTAssertEqual(owned.first, startOfDay(2026, 7, 25))
        XCTAssertEqual(owned.last, startOfDay(2026, 8, 24))
        XCTAssertTrue(owned.allSatisfy { cycle.contains($0) })
    }

    /// Leading and trailing filler is marked out-of-cycle.
    func testFillerDaysAreOutOfCycle() {
        let grid = cycleCalendar(for: augustCycle, expenses: [], calendar: calendar)
        let byDate = Dictionary(uniqueKeysWithValues: grid.days.map { ($0.date, $0) })

        for day in 19...24 {
            XCTAssertEqual(byDate[startOfDay(2026, 7, day)]?.inCycle, false, "19–24 Jul is filler")
        }
        for day in 25...29 {
            XCTAssertEqual(byDate[startOfDay(2026, 8, day)]?.inCycle, false, "25–29 Aug is filler")
        }
    }

    // MARK: - Day spend

    /// A day's total and count come from its own expenses.
    func testDayTotalsMatchFixtures() {
        let grid = cycleCalendar(for: augustCycle, expenses: seeded, calendar: calendar)
        let byDate = Dictionary(uniqueKeysWithValues: grid.days.map { ($0.date, $0) })

        // 2 Aug has two expenses (120.000 + 25.000).
        XCTAssertEqual(byDate[startOfDay(2026, 8, 2)]?.total, 145_000)
        XCTAssertEqual(byDate[startOfDay(2026, 8, 2)]?.count, 2)
        XCTAssertEqual(byDate[startOfDay(2026, 8, 5)]?.total, 45_000)
        XCTAssertEqual(byDate[startOfDay(2026, 8, 5)]?.count, 1)
        XCTAssertEqual(byDate[startOfDay(2026, 8, 6)]?.total, 30_000)
        XCTAssertEqual(byDate[startOfDay(2026, 7, 28)]?.total, 80_000)
    }

    /// A day the cycle doesn't own contributes nothing, even when an expense sits on
    /// it — the 20 Jul latte must not leak into the August grid.
    func testOutOfCycleExpenseIsExcluded() {
        let grid = cycleCalendar(for: augustCycle, expenses: seeded, calendar: calendar)
        let byDate = Dictionary(uniqueKeysWithValues: grid.days.map { ($0.date, $0) })

        // 20 Jul *is* drawn (the grid opens on Sun 19 Jul) but only as filler, so it
        // must carry no spend — and the cycle's own sum must exclude it.
        XCTAssertEqual(byDate[startOfDay(2026, 7, 20)]?.inCycle, false)
        XCTAssertEqual(byDate[startOfDay(2026, 7, 20)]?.total, 0)
        XCTAssertEqual(byDate[startOfDay(2026, 7, 20)]?.count, 0)
        XCTAssertEqual(grid.cycleDays.reduce(Decimal(0)) { $0 + $1.total }, 300_000)
        XCTAssertEqual(grid.cycleDays.reduce(0) { $0 + $1.count }, 5)
    }

    /// Paging back to the July cycle brings the 20 Jul latte in-cycle.
    func testPreviousCycleOwnsTheJulyExpense() {
        let july = augustCycle.previous(payday: 25, calendar: calendar)
        let grid = cycleCalendar(for: july, expenses: seeded, calendar: calendar)
        let byDate = Dictionary(uniqueKeysWithValues: grid.days.map { ($0.date, $0) })

        XCTAssertEqual(byDate[startOfDay(2026, 7, 20)]?.inCycle, true)
        XCTAssertEqual(byDate[startOfDay(2026, 7, 20)]?.total, 25_000)
        XCTAssertEqual(grid.maxDayTotal, 25_000)
    }

    /// maxDayTotal is the heaviest in-cycle day, and zero for an empty cycle.
    func testMaxDayTotal() {
        XCTAssertEqual(cycleCalendar(for: augustCycle, expenses: seeded, calendar: calendar).maxDayTotal, 145_000)
        XCTAssertEqual(cycleCalendar(for: augustCycle, expenses: [], calendar: calendar).maxDayTotal, 0)
    }

    // MARK: - Intensity

    /// Buckets, including the documented ratio edges. A boundary ratio falls in the
    /// *lower* bucket (thresholds are strict `>`).
    func testDayIntensityBuckets() {
        XCTAssertEqual(dayIntensity(total: 0, max: 145_000), .none)
        XCTAssertEqual(dayIntensity(total: 50_000, max: 0), .none, "empty cycle ⇒ no dot")

        XCTAssertEqual(dayIntensity(total: 145_000, max: 145_000), .heaviest)
        XCTAssertEqual(dayIntensity(total: 80_000, max: 145_000), .heavy)   // 0.55
        XCTAssertEqual(dayIntensity(total: 45_000, max: 145_000), .medium)  // 0.31
        XCTAssertEqual(dayIntensity(total: 30_000, max: 145_000), .light)   // 0.21

        // Exact edges: a ratio sitting *on* a threshold stays in the lower bucket.
        XCTAssertEqual(dayIntensity(total: 75, max: 100), .heavy)
        XCTAssertEqual(dayIntensity(total: 76, max: 100), .heaviest)
        XCTAssertEqual(dayIntensity(total: 50, max: 100), .medium)
        XCTAssertEqual(dayIntensity(total: 51, max: 100), .heavy)
        XCTAssertEqual(dayIntensity(total: 25, max: 100), .light)
        XCTAssertEqual(dayIntensity(total: 26, max: 100), .medium)
    }

    /// The four seeded days land in four distinct buckets, so the grid actually
    /// communicates "which days were heavy".
    func testSeededDaysProduceDistinctIntensities() {
        let grid = cycleCalendar(for: augustCycle, expenses: seeded, calendar: calendar)
        let byDate = Dictionary(uniqueKeysWithValues: grid.days.map { ($0.date, $0) })
        let buckets = [(8, 2), (7, 28), (8, 5), (8, 6)].map { month, day -> DayIntensity in
            let cell = byDate[startOfDay(2026, month, day)]!
            return dayIntensity(total: cell.total, max: grid.maxDayTotal)
        }

        XCTAssertEqual(buckets, [.heaviest, .heavy, .medium, .light])
    }

    // MARK: - Abbreviated cell total

    /// The cell prints the day's total abbreviated to thousands (a ~48pt column can't
    /// hold "Rp145.000"). Nothing at all on a day with no spend.
    func testAbbreviatedDayTotal() {
        XCTAssertNil(abbreviatedDayTotal(0))
        XCTAssertNil(abbreviatedDayTotal(-5_000))

        XCTAssertEqual(abbreviatedDayTotal(145_000), "145k")
        XCTAssertEqual(abbreviatedDayTotal(80_000), "80k")
        XCTAssertEqual(abbreviatedDayTotal(45_000), "45k")
        XCTAssertEqual(abbreviatedDayTotal(30_000), "30k")
    }

    /// Rounds to the nearest thousand, and floors at 1k so a small nonzero day still
    /// reads as spending rather than "0k".
    func testAbbreviatedDayTotalRoundsAndFloors() {
        XCTAssertEqual(abbreviatedDayTotal(145_400), "145k")
        XCTAssertEqual(abbreviatedDayTotal(145_600), "146k")
        XCTAssertEqual(abbreviatedDayTotal(500), "1k")
        XCTAssertEqual(abbreviatedDayTotal(1), "1k")
    }

    /// A millions-scale day stays in thousands rather than growing a second unit.
    func testAbbreviatedDayTotalStaysInThousands() {
        XCTAssertEqual(abbreviatedDayTotal(1_200_000), "1200k")
    }

    /// Every seeded day's cell text fits the four-to-five glyph budget of a column.
    func testAbbreviatedDayTotalsFitTheCell() {
        let grid = cycleCalendar(for: augustCycle, expenses: seeded, calendar: calendar)

        let labels = grid.cycleDays.compactMap { abbreviatedDayTotal($0.total) }

        XCTAssertEqual(labels.sorted(), ["145k", "30k", "45k", "80k"])
        XCTAssertTrue(labels.allSatisfy { $0.count <= 5 })
    }

    // MARK: - Locale + boundary math

    /// A Monday-first calendar puts Monday in column 0 and still yields whole weeks.
    func testMondayFirstLocale() {
        var monday = Calendar(identifier: .gregorian)
        monday.firstWeekday = 2
        let cycle = PayCycle.containing(date(2026, 8, 16, 12, 0), payday: 25, calendar: monday)

        let grid = cycleCalendar(for: cycle, expenses: [], calendar: monday)

        XCTAssertTrue(grid.weeks.allSatisfy { $0.count == 7 })
        // 25 Jul 2026 is a Saturday ⇒ its Monday-first week opens Mon 20 Jul.
        XCTAssertEqual(grid.weeks.first?.first?.date, startOfDay(2026, 7, 20))
        XCTAssertEqual(monday.component(.weekday, from: grid.weeks[0][0].date), 2)
        XCTAssertEqual(grid.cycleDays.count, 31)
    }

    /// A cycle clamped by a short month (payday 31 ⇒ Jan 31 → Feb 28) still lays out
    /// whole weeks with every one of its days present exactly once.
    func testShortMonthCycle() {
        let cycle = PayCycle.containing(date(2026, 2, 10, 12, 0), payday: 31, calendar: calendar)
        let grid = cycleCalendar(for: cycle, expenses: [], calendar: calendar)

        XCTAssertEqual(cycle.start, startOfDay(2026, 1, 31))
        XCTAssertEqual(cycle.lastDay(calendar: calendar), startOfDay(2026, 2, 27))
        XCTAssertTrue(grid.weeks.allSatisfy { $0.count == 7 })

        let owned = grid.cycleDays.map(\.date)
        XCTAssertEqual(owned.count, Set(owned).count)
        XCTAssertEqual(owned.count, 28)
        XCTAssertEqual(owned.first, cycle.start)
        XCTAssertEqual(owned.last, cycle.lastDay(calendar: calendar))
    }

    // MARK: - Default selection

    /// Today wins when the cycle owns it.
    func testDefaultSelectionPrefersToday() {
        let grid = cycleCalendar(for: augustCycle, expenses: seeded, calendar: calendar)

        let selected = defaultSelectedDay(in: grid, today: date(2026, 8, 16, 21, 35), calendar: calendar)

        XCTAssertEqual(selected, startOfDay(2026, 8, 16))
    }

    /// Browsing an older cycle falls back to its most recent day with spending.
    func testDefaultSelectionFallsBackToLatestSpendingDay() {
        let grid = cycleCalendar(for: augustCycle, expenses: seeded, calendar: calendar)

        // "Today" is far in the future, so the August cycle doesn't own it.
        let selected = defaultSelectedDay(in: grid, today: date(2027, 1, 1, 9, 0), calendar: calendar)

        XCTAssertEqual(selected, startOfDay(2026, 8, 6))
    }

    /// A cycle with no spending at all falls back to its last day.
    func testDefaultSelectionFallsBackToLastDay() {
        let grid = cycleCalendar(for: augustCycle, expenses: [], calendar: calendar)

        let selected = defaultSelectedDay(in: grid, today: date(2027, 1, 1, 9, 0), calendar: calendar)

        XCTAssertEqual(selected, startOfDay(2026, 8, 24))
    }

    // MARK: - Helpers

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func startOfDay(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.startOfDay(for: calendar.date(from: DateComponents(year: y, month: m, day: d))!)
    }
}
