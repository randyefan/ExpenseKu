//
//  InsightsDrillInTests.swift
//  ExpenseKuTests
//
//  docs/prd/insights-drill-in.md, one test per rule, on the PRD's own sample (§10):
//  payday 31, today Thu 6 August 2026; June held only the plan's Fixed rows, July adds
//  165.000 outside the plan, and only August's plan has the Hidup envelope.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class InsightsDrillInTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let payday = 31

    private func date(_ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: m, day: d, hour: h)) ?? .distantPast
    }

    private var today: Date { date(8, 6, 21) }

    private func cycle(_ m: Int, _ d: Int) -> PayCycle {
        PayCycle.containing(date(m, d), payday: payday, calendar: calendar)
    }

    private struct Sample {
        let plans: [CyclePlan]
        let expenses: [Expense]
        let makan: Category
        let gopay: Account
        let cash: Account
    }

    @MainActor
    private func sample(_ context: ModelContext) throws -> Sample {
        let makan = Category(name: "Makan")
        let kopi = Category(name: "Kopi")
        let transport = Category(name: "Transport")
        let housing = Category(name: "Kos")
        [makan, kopi, transport, housing].forEach(context.insert)
        let bca = Account(name: "BCA")
        let bni = Account(name: "BNI")
        let gopay = Account(name: "GoPay")
        let cash = Account(name: "Cash")
        [bca, bni, gopay, cash].forEach(context.insert)

        var plans: [CyclePlan] = []
        var expenses: [Expense] = []
        func payday(on day: Date, envelope: Bool) {
            let plan = CyclePlan(cycleStart: PayCycle.containing(day, payday: self.payday, calendar: calendar).start)
            context.insert(plan)
            plans.append(plan)
            for (name, amount, account) in [("Kos", Decimal(2_500_000), bca),
                                            ("Cicilan Rumah", Decimal(1_500_000), bni),
                                            ("Internet", Decimal(350_000), bca)] {
                let item = PlanItem(name: name, amount: amount, plan: plan, category: housing, account: account)
                context.insert(item)
                expenses.append(Expense(amount: amount, date: day, note: name, category: housing,
                                        account: account, planItem: item))
            }
            if envelope {
                context.insert(PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                        plan: plan, envelopeCategories: [makan]))
            }
        }
        payday(on: date(5, 31, 9), envelope: false)
        payday(on: date(6, 30, 9), envelope: false)
        payday(on: date(7, 31, 9), envelope: true)
        expenses += [
            Expense(amount: 60_000, date: date(7, 12), note: "Lunch", category: makan, account: cash),
            Expense(amount: 10_000, date: date(7, 18), note: "Parkir", category: transport),
            Expense(amount: 55_000, date: date(7, 20), note: "Dinner", category: makan, account: gopay),
            Expense(amount: 40_000, date: date(7, 25), note: "Iced latte", category: kopi, account: gopay),
            Expense(amount: 25_000, date: date(8, 2, 8), note: "Morning coffee", category: kopi, account: cash),
            Expense(amount: 120_000, date: date(8, 2, 20), note: "Dinner", category: makan, account: gopay),
            Expense(amount: 45_000, date: date(8, 5, 13), note: "Lunch", category: makan, account: cash),
            Expense(amount: 30_000, date: date(8, 6, 18), note: "Grab home", category: transport, account: gopay),
        ]
        expenses.forEach(context.insert)
        try context.save()
        return Sample(plans: plans, expenses: expenses, makan: makan, gopay: gopay, cash: cash)
    }

    private func origins(_ sample: Sample) -> PlanOrigins {
        PlanOrigins(plans: sample.plans, payday: payday, calendar: calendar)
    }

    private func window(_ preset: DateRangeFilter, _ cycle: PayCycle? = nil) -> ClosedRange<Date>? {
        InsightsWindow(preset: preset, cycle: cycle).range(now: today, payday: payday, calendar: calendar)
    }

    private func inWindow(_ sample: Sample, _ range: ClosedRange<Date>?) -> [Expense] {
        sample.expenses.filter { range?.contains($0.date) ?? true }
    }

    private func detail(
        _ sample: Sample,
        _ subject: SpendSubject,
        narrowing: SpendSubject? = nil,
        _ range: ClosedRange<Date>?,
        _ filter: PlanFilter?
    ) -> SpendEntityDetail {
        SpendEntityDetail(expenses: sample.expenses, subject: subject, narrowing: narrowing,
                          dateRange: range, planFilter: filter, origins: origins(sample))
    }

    private func names(_ rows: [SpendBreakdownRow]) -> [String] { rows.map(\.name) }

    // MARK: - §4.1 Rows open a detail screen

    @MainActor
    func testBreakdownRowsCarryTheirSubject() throws {
        let sample = try sample(try makeInMemoryContext())
        let july = inWindow(sample, window(.payPeriod, cycle(7, 15)))

        let categories = SpendSummary.byCategory(from: july)
        XCTAssertEqual(categories.first { $0.categoryName == "Makan" }?.subject,
                       .category(sample.makan.persistentModelID))
        let accounts = SpendSummary.byAccount(from: july)
        XCTAssertEqual(accounts.first { $0.accountName == "GoPay" }?.subject,
                       .account(sample.gopay.persistentModelID))
        XCTAssertEqual(accounts.first { $0.accountName == "Unassigned" }?.subject, .unassigned)
    }

    @MainActor
    func testUncategorizedAndUnassignedMatchTheNilCases() throws {
        let sample = try sample(try makeInMemoryContext())
        let parkir = try XCTUnwrap(sample.expenses.first { $0.note == "Parkir" })
        let uncategorized = Expense(amount: 5_000, date: date(7, 19))

        XCTAssertTrue(SpendSubject.unassigned.matches(parkir))
        XCTAssertFalse(SpendSubject.unassigned.matches(sample.expenses[0]))
        XCTAssertTrue(SpendSubject.uncategorized.matches(uncategorized))
        XCTAssertFalse(SpendSubject.uncategorized.matches(parkir))
        XCTAssertEqual(SpendSummary.byCategory(from: [uncategorized]).first?.subject, .uncategorized)
    }

    @MainActor
    func testADeletedSubjectResolvesToNothingButTheNilCasesNeverDo() throws {
        let context = try makeInMemoryContext()
        let sample = try sample(context)
        let makan = SpendSubject.category(sample.makan.persistentModelID)
        XCTAssertEqual(SpendEntityIdentity.resolve(makan, in: context)?.name, "Makan")

        context.delete(sample.makan)
        try context.save()

        XCTAssertNil(SpendEntityIdentity.resolve(makan, in: context))
        XCTAssertEqual(SpendEntityIdentity.resolve(.uncategorized, in: context)?.name, "Uncategorized")
        XCTAssertEqual(SpendEntityIdentity.resolve(.unassigned, in: context)?.kind, "Account")
    }

    // MARK: - §4.2 The detail screen

    @MainActor
    func testMakanInJulyOutsidePlanIsO4() throws {
        let sample = try sample(try makeInMemoryContext())
        let makan = detail(sample, .category(sample.makan.persistentModelID),
                           window(.payPeriod, cycle(7, 15)), .outsidePlan)

        XCTAssertEqual(makan.total, 115_000)
        XCTAssertEqual(makan.listed.map(\.note), ["Lunch", "Dinner"])
        XCTAssertEqual(try XCTUnwrap(makan.share), 115.0 / 165.0, accuracy: 0.0001)
        XCTAssertEqual(makan.split, SpendingSplit(outsidePlan: 115_000, fromPlan: 0))
        XCTAssertEqual(names(makan.breakdown), ["Cash", "GoPay"])
        XCTAssertEqual(makan.breakdown.map(\.total), [60_000, 55_000])
    }

    @MainActor
    func testTheAccountVariantBreaksDownByCategoryIsO7() throws {
        let sample = try sample(try makeInMemoryContext())
        let gopay = detail(sample, .account(sample.gopay.persistentModelID), window(.payPeriod), nil)

        XCTAssertEqual(gopay.total, 150_000)
        XCTAssertEqual(gopay.split, SpendingSplit(outsidePlan: 30_000, fromPlan: 120_000))
        XCTAssertEqual(names(gopay.breakdown), ["Makan", "Transport"])
        XCTAssertEqual(try XCTUnwrap(gopay.share), 150.0 / 4_570.0, accuracy: 0.0001)
    }

    @MainActor
    func testTheBreakdownDropsAnEmptyBucket() throws {
        let sample = try sample(try makeInMemoryContext())
        let makan = detail(sample, .category(sample.makan.persistentModelID), window(.payPeriod), nil)

        XCTAssertEqual(names(makan.breakdown), ["GoPay", "Cash"])
        XCTAssertFalse(names(makan.breakdown).contains("Unassigned"))
    }

    @MainActor
    func testNothingInTheWindowHasNoShareAndNoBreakdown() throws {
        let sample = try sample(try makeInMemoryContext())
        let makan = detail(sample, .category(sample.makan.persistentModelID), window(.payPeriod, cycle(6, 15)), nil)

        XCTAssertEqual(makan.total, 0)
        XCTAssertNil(makan.share)
        XCTAssertTrue(makan.breakdown.isEmpty)
        XCTAssertTrue(makan.listed.isEmpty)
    }

    // MARK: - §4.3 Narrowing

    @MainActor
    func testNarrowingFollowsTheHeaderAndKeepsTheBreakdownIsO6() throws {
        let sample = try sample(try makeInMemoryContext())
        let makan = detail(sample, .category(sample.makan.persistentModelID),
                           narrowing: .account(sample.gopay.persistentModelID),
                           window(.allTime), .outsidePlan)

        XCTAssertEqual(makan.total, 55_000)
        XCTAssertEqual(makan.listed.map(\.note), ["Dinner"])
        XCTAssertEqual(try XCTUnwrap(makan.share), 55.0 / 220.0, accuracy: 0.0001)
        XCTAssertEqual(makan.split, SpendingSplit(outsidePlan: 55_000, fromPlan: 120_000))
        XCTAssertEqual(names(makan.breakdown), ["Cash", "GoPay"])
        XCTAssertEqual(makan.breakdown.map(\.total), [60_000, 55_000])
    }

    // MARK: - §4.4 Empty

    func testEmptyWordingNamesTheHalfAndTheWindow() {
        XCTAssertEqual(SpendEntityDetail.emptyTitle(planFilter: nil), "Nothing in This Window")
        XCTAssertEqual(SpendEntityDetail.emptyTitle(planFilter: .outsidePlan), "Nothing outside the plan")
        XCTAssertEqual(SpendEntityDetail.emptyMessage(name: "Makan", planFilter: nil, windowPhrase: "in July 2026"),
                       "Makan has no expenses in July 2026.")
        XCTAssertEqual(SpendEntityDetail.emptyMessage(name: "Makan", planFilter: .outsidePlan,
                                                      windowPhrase: "in August 2026"),
                       "Makan has no expenses outside the plan in August 2026.")
    }

    @MainActor
    func testAnEmptyHalfOnTheDetailIsO9() throws {
        let sample = try sample(try makeInMemoryContext())
        let makan = detail(sample, .category(sample.makan.persistentModelID), window(.payPeriod), .outsidePlan)

        XCTAssertEqual(makan.total, 0)
        XCTAssertNil(makan.share)
        XCTAssertTrue(makan.breakdown.isEmpty)
        XCTAssertEqual(makan.split, SpendingSplit(outsidePlan: 0, fromPlan: 165_000))
    }

    // MARK: - §5.1 The chip

    func testTheChipReadsPayPeriodOnInsightsOnly() {
        XCTAssertEqual(InsightsWindow.chipLabel(for: .payPeriod), "Pay period")
        XCTAssertEqual(InsightsWindow.chipLabel(for: .thisMonth), "This month")
        XCTAssertEqual(DateRangeFilter.payPeriod.label, "This pay period")
    }

    // MARK: - §5.2 The menu

    func testTheMenuRunsFromTheCurrentCycleBackToTheOldestExpense() {
        let cycles = PayPeriodChoices.cycles(oldestExpense: date(5, 31, 9), now: today,
                                             payday: payday, calendar: calendar)
        XCTAssertEqual(cycles.map { $0.title(calendar: calendar) }, ["August 2026", "July 2026", "June 2026"])
    }

    func testAnEmptyCycleInBetweenIsListedAndNoFutureOne() {
        let cycles = PayPeriodChoices.cycles(oldestExpense: date(3, 15), now: today,
                                             payday: payday, calendar: calendar)
        XCTAssertEqual(cycles.first, cycle(8, 6))
        XCTAssertEqual(cycles.count, 6)
        XCTAssertTrue(cycles.allSatisfy { $0.start <= today })
    }

    func testWithNoExpensesTheMenuHoldsTheCurrentCycleAlone() {
        XCTAssertEqual(PayPeriodChoices.cycles(oldestExpense: nil, now: today, payday: payday, calendar: calendar),
                       [cycle(8, 6)])
    }

    func testMenuItemsShowTheTitleOverTheRange() {
        XCTAssertEqual(cycle(7, 15).title(calendar: calendar), "July 2026")
        XCTAssertEqual(cycle(7, 15).rangeText(calendar: calendar), "30/06/2026 ~ 30/07/2026")
    }

    // MARK: - §5.3 The window

    func testAPastCycleIsItsWholeSpanAndTheCurrentOneEndsNow() {
        let july = cycle(7, 15)
        let past = try? XCTUnwrap(window(.payPeriod, july))
        XCTAssertEqual(past?.lowerBound, july.start)
        XCTAssertTrue(past?.contains(date(7, 30, 23)) ?? false)
        XCTAssertFalse(past?.contains(july.end) ?? true)

        let current = window(.payPeriod)
        XCTAssertEqual(current?.lowerBound, cycle(8, 6).start)
        XCTAssertEqual(current?.upperBound, today)
    }

    func testPickingTheCurrentCycleStoresNothingAndRepickingChangesNothing() {
        var insights = InsightsWindow(preset: .payPeriod)
        XCTAssertTrue(insights.select(cycle(7, 15), now: today))
        XCTAssertEqual(insights.cycle, cycle(7, 15))
        XCTAssertFalse(insights.select(cycle(7, 15), now: today))
        XCTAssertTrue(insights.select(cycle(8, 6), now: today))
        XCTAssertNil(insights.cycle)
    }

    func testTheWindowIsNamedByTheCycleTitle() {
        let july = InsightsWindow(preset: .payPeriod, cycle: cycle(7, 15))
        XCTAssertEqual(july.label(now: today, payday: payday, calendar: calendar), "July 2026")
        XCTAssertEqual(july.phrase(now: today, payday: payday, calendar: calendar), "in July 2026")
        let current = InsightsWindow(preset: .payPeriod)
        XCTAssertEqual(current.label(now: today, payday: payday, calendar: calendar), "August 2026")
        XCTAssertEqual(InsightsWindow(preset: .allTime).phrase(now: today, payday: payday, calendar: calendar), "at all")
    }

    func testTheChosenCycleSurvivesAChipChange() {
        var insights = InsightsWindow(preset: .payPeriod, cycle: cycle(7, 15))
        insights.preset = .allTime
        insights.preset = .payPeriod
        XCTAssertEqual(insights.cycle, cycle(7, 15))
    }

    // MARK: - §5.4 Spend over Time

    func testTheTrendWindowEndsAtTheCurrentCycleWhileTheSelectionIsInside() {
        let window = PayPeriodChoices.trendWindow(count: 12, selected: cycle(7, 15), now: today,
                                                  payday: payday, calendar: calendar)
        XCTAssertEqual(window.count, 12)
        XCTAssertEqual(window.last, cycle(8, 6))
    }

    func testTheTrendWindowSlidesBackOnlyForAnOlderSelection() {
        let old = PayCycle.containing(date(1, 15).addingTimeInterval(-86_400 * 365), payday: payday, calendar: calendar)
        let window = PayPeriodChoices.trendWindow(count: 12, selected: old, now: today,
                                                  payday: payday, calendar: calendar)
        XCTAssertEqual(window.count, 12)
        XCTAssertEqual(window.last, old)
    }

    // MARK: - §6 Plan filter

    @MainActor
    func testEachExpenseIsJudgedByItsOwnCyclesPlanIsO5() throws {
        let sample = try sample(try makeInMemoryContext())
        let makan = detail(sample, .category(sample.makan.persistentModelID), window(.allTime), nil)

        XCTAssertEqual(makan.total, 280_000)
        XCTAssertEqual(makan.split, SpendingSplit(outsidePlan: 115_000, fromPlan: 165_000))
    }

    @MainActor
    func testTheSpendingCardSplitsTheWholeWindow() throws {
        let sample = try sample(try makeInMemoryContext())
        let split = { (range: ClosedRange<Date>?) in self.origins(sample).split(self.inWindow(sample, range)) }

        XCTAssertEqual(split(window(.payPeriod, cycle(6, 15))), SpendingSplit(outsidePlan: 0, fromPlan: 4_350_000))
        XCTAssertEqual(split(window(.payPeriod, cycle(7, 15))), SpendingSplit(outsidePlan: 165_000, fromPlan: 4_350_000))
        XCTAssertEqual(split(window(.payPeriod)), SpendingSplit(outsidePlan: 55_000, fromPlan: 4_515_000))
        XCTAssertEqual(split(window(.allTime)), SpendingSplit(outsidePlan: 220_000, fromPlan: 13_215_000))
    }

    @MainActor
    func testFilteredChartsHoldOnlyTheHalfIsO3() throws {
        let sample = try sample(try makeInMemoryContext())
        let july = inWindow(sample, window(.payPeriod, cycle(7, 15)))
        let outside = origins(sample).expenses(july, matching: .outsidePlan)

        XCTAssertEqual(SpendSummary.byCategory(from: outside).map(\.categoryName), ["Makan", "Kopi", "Transport"])
        XCTAssertEqual(SpendSummary.byAccount(from: outside).map(\.total), [95_000, 60_000, 10_000])
    }

    @MainActor
    func testTheTrendFollowsTheFilterPerCycleIsO8() throws {
        let sample = try sample(try makeInMemoryContext())
        let window = PayPeriodChoices.trendWindow(count: 12, selected: cycle(6, 15), now: today,
                                                  payday: payday, calendar: calendar)
        let outside = origins(sample).expenses(sample.expenses, matching: .outsidePlan)
        let bars = SpendSummary.byPayPeriod(from: outside, window: window, calendar: calendar)

        XCTAssertEqual(bars.map(\.total), [165_000, 55_000])
    }

    func testAnEmptyChartNamesTheHalf() {
        XCTAssertEqual(PlanFilter.outsidePlan.emptyPeriodMessage, "Nothing outside the plan in this period.")
        XCTAssertEqual(PlanFilter.fromPlan.emptyPeriodMessage, "Nothing from the plan in this period.")
    }

    func testAFilterOnKeepsTheChipsAtFromPlanZero() {
        XCTAssertFalse(PlanFilter.showsLegend(for: SpendingSplit(outsidePlan: 1_250_000), filter: nil))
        XCTAssertTrue(PlanFilter.showsLegend(for: SpendingSplit(outsidePlan: 1_250_000), filter: .fromPlan))
    }
}
