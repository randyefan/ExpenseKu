//
//  PlanFilterTests.swift
//  ExpenseKuTests
//
//  docs/prd/plan-filter.md, one test per rule, on the PRD's own sample cycle: August 2026
//  (31/07 – 30/08, payday 31), today Thu 6 August.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class PlanFilterTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: m, day: d, hour: h)) ?? .distantPast
    }

    private var cycle: PayCycle {
        PayCycle.containing(date(8, 6), payday: 31, calendar: calendar)
    }

    private struct Sample {
        let plans: [CyclePlan]
        let expenses: [Expense]
    }

    @MainActor
    private func sample(_ context: ModelContext, onlyPayday: Bool = false) throws -> Sample {
        let makan = Category(name: "Makan")
        let kopi = Category(name: "Kopi")
        let transport = Category(name: "Transport")
        [makan, kopi, transport].forEach(context.insert)
        let plan = CyclePlan(cycleStart: cycle.start)
        context.insert(plan)
        let kos = PlanItem(name: "Kos", amount: 2_500_000, plan: plan)
        let cicilan = PlanItem(name: "Cicilan Rumah", amount: 1_500_000, plan: plan)
        let internet = PlanItem(name: "Internet", amount: 350_000, plan: plan)
        [kos, cicilan, internet].forEach(context.insert)
        context.insert(PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                plan: plan, envelopeCategories: [makan]))
        var expenses = [
            Expense(amount: 2_500_000, date: date(7, 31, 9), planItem: kos),
            Expense(amount: 1_500_000, date: date(7, 31, 10), planItem: cicilan),
            Expense(amount: 350_000, date: date(7, 31, 11), planItem: internet),
        ]
        if !onlyPayday {
            expenses += [
                Expense(amount: 25_000, date: date(8, 2, 8), note: "Morning coffee", category: kopi),
                Expense(amount: 120_000, date: date(8, 2, 20), note: "Dinner", category: makan),
                Expense(amount: 45_000, date: date(8, 5, 13), note: "Lunch", category: makan),
                Expense(amount: 30_000, date: date(8, 6, 18), note: "Grab home", category: transport),
            ]
        }
        expenses.forEach(context.insert)
        try context.save()
        return Sample(plans: [plan], expenses: expenses)
    }

    private func origins(_ sample: Sample) -> PlanOrigins {
        PlanOrigins(plans: sample.plans, payday: 31, calendar: calendar)
    }

    private func shown(_ sample: Sample, _ filter: PlanFilter) -> [Expense] {
        origins(sample).expenses(sample.expenses, in: cycle, matching: filter)
    }

    private func total(_ expenses: [Expense]) -> Decimal {
        expenses.reduce(0) { $0 + $1.amount }
    }

    // MARK: - §4.1 States and the control

    func testTappingFollowsTheStateTable() {
        XCTAssertEqual(PlanFilter.tapping(.outsidePlan, on: nil), .outsidePlan)
        XCTAssertEqual(PlanFilter.tapping(.fromPlan, on: nil), .fromPlan)
        XCTAssertNil(PlanFilter.tapping(.outsidePlan, on: .outsidePlan))
        XCTAssertEqual(PlanFilter.tapping(.fromPlan, on: .outsidePlan), .fromPlan)
        XCTAssertEqual(PlanFilter.tapping(.outsidePlan, on: .fromPlan), .outsidePlan)
        XCTAssertNil(PlanFilter.tapping(.fromPlan, on: .fromPlan))
    }

    @MainActor
    func testFromPlanHoldsFixedAndEnvelopeRowsAndAddsUpToTheLegend() throws {
        let sample = try sample(try makeInMemoryContext())
        let fromPlan = shown(sample, .fromPlan)

        XCTAssertEqual(fromPlan.map(\.amount).sorted(), [45_000, 120_000, 350_000, 1_500_000, 2_500_000])
        XCTAssertEqual(total(fromPlan), origins(sample).split(sample.expenses, in: cycle).fromPlan)
        XCTAssertEqual(total(fromPlan), 4_515_000)
    }

    @MainActor
    func testOutsidePlanHoldsUntaggedRowsAndAddsUpToTheLegend() throws {
        let sample = try sample(try makeInMemoryContext())
        let outside = shown(sample, .outsidePlan)

        XCTAssertEqual(outside.map(\.note).sorted(), ["Grab home", "Morning coffee"])
        XCTAssertEqual(total(outside), origins(sample).split(sample.expenses, in: cycle).outsidePlan)
        XCTAssertEqual(total(outside), 55_000)
    }

    func testNoPlanSpendingMeansNoLegendAndSoNoFilter() {
        XCTAssertFalse(PlanFilter.showsLegend(for: SpendingSplit(outsidePlan: 55_000, fromPlan: 0), filter: nil))
        XCTAssertTrue(PlanFilter.showsLegend(for: SpendingSplit(outsidePlan: 55_000, fromPlan: 1), filter: nil))
    }

    func testTheLegendStaysWhileFilteredEvenAtFromPlanZero() {
        let lastPlanRowDeleted = SpendingSplit(outsidePlan: 55_000, fromPlan: 0)
        XCTAssertTrue(PlanFilter.showsLegend(for: lastPlanRowDeleted, filter: .fromPlan))
        XCTAssertTrue(PlanFilter.showsLegend(for: lastPlanRowDeleted, filter: .outsidePlan))
    }

    @MainActor
    func testAnEmptyHalfFiltersToNothing() throws {
        let sample = try sample(try makeInMemoryContext(), onlyPayday: true)
        XCTAssertTrue(shown(sample, .outsidePlan).isEmpty)
        XCTAssertEqual(total(shown(sample, .fromPlan)), 4_350_000)
    }

    // MARK: - §4.2 List lens

    @MainActor
    func testDayHeadersAddUpVisibleRowsAndEmptyDaysDisappear() throws {
        let sample = try sample(try makeInMemoryContext())
        let contents = CycleContents(cycle: cycle, allExpenses: shown(sample, .outsidePlan), calendar: calendar)

        XCTAssertEqual(contents.dayGroups.map(\.total), [30_000, 25_000])
        XCTAssertNil(contents.group(for: calendar.startOfDay(for: date(8, 5))))
        XCTAssertNil(contents.group(for: calendar.startOfDay(for: date(7, 31))))
    }

    // MARK: - §4.3 Month lens

    @MainActor
    func testMonthCellsShowTheHalfAndWeighAgainstItsHeaviestDay() throws {
        let sample = try sample(try makeInMemoryContext())
        let grid = cycleCalendar(for: cycle, expenses: shown(sample, .outsidePlan), calendar: calendar)
        let cell = { (m: Int, d: Int) in grid.days.first { $0.date == self.calendar.startOfDay(for: self.date(m, d)) } }

        XCTAssertEqual(grid.maxDayTotal, 30_000)
        XCTAssertEqual(cell(7, 31)?.total, 0)
        XCTAssertEqual(cell(8, 5)?.total, 0)
        XCTAssertEqual(cell(8, 2)?.total, 25_000)
        XCTAssertEqual(dayIntensity(total: 25_000, max: grid.maxDayTotal), .heaviest)
    }

    @MainActor
    func testTheDefaultDayKeepsTodayEvenWhenTodayHasNothingInTheHalf() throws {
        let sample = try sample(try makeInMemoryContext())
        let grid = cycleCalendar(for: cycle, expenses: shown(sample, .fromPlan), calendar: calendar)

        XCTAssertEqual(defaultSelectedDay(in: grid, today: date(8, 6), calendar: calendar),
                       calendar.startOfDay(for: date(8, 6)))
    }

    @MainActor
    func testTheDefaultDayOutsideTheCycleIsTheLastDayWithFilteredSpending() throws {
        let sample = try sample(try makeInMemoryContext())
        let grid = cycleCalendar(for: cycle, expenses: shown(sample, .outsidePlan), calendar: calendar)
        let fromPlanGrid = cycleCalendar(for: cycle, expenses: shown(sample, .fromPlan), calendar: calendar)

        XCTAssertEqual(defaultSelectedDay(in: grid, today: date(10, 3), calendar: calendar),
                       calendar.startOfDay(for: date(8, 6)))
        XCTAssertEqual(defaultSelectedDay(in: fromPlanGrid, today: date(10, 3), calendar: calendar),
                       calendar.startOfDay(for: date(8, 5)))
    }

    // MARK: - §4.4 Empty half, §4.5 the pill

    func testEmptyMessagesNameTheHalf() {
        XCTAssertEqual(PlanFilter.outsidePlan.emptyCycleTitle, "Nothing outside the plan")
        XCTAssertEqual(PlanFilter.fromPlan.emptyCycleTitle, "Nothing from the plan")
        XCTAssertEqual(PlanFilter.outsidePlan.emptyCycleDetail(span: "31/07/2026 – 30/08/2026"),
                       "No expenses outside the plan in 31/07/2026 – 30/08/2026.")
        XCTAssertEqual(PlanFilter.fromPlan.emptyDayTitle(dayPhrase: "today"), "Nothing from the plan today")
        XCTAssertEqual(PlanFilter.outsidePlan.emptyDayTitle(dayPhrase: "on Sun, 2 August"),
                       "Nothing outside the plan on Sun, 2 August")
        XCTAssertEqual(PlanFilter.fromPlan.emptyDayDetail, "Tap From plan again to show every expense.")
    }

    func testThePillNamesTheHalf() {
        XCTAssertEqual(PlanFilter.outsidePlan.pillTitle, "Outside plan only")
        XCTAssertEqual(PlanFilter.fromPlan.pillTitle, "From plan only")
    }
}
