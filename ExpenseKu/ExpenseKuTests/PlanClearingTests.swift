//
//  PlanClearingTests.swift
//  ExpenseKuTests
//
//  Flow AH (docs/prd/clear-plan.md), one test per rule, against the flow's sample: payday 1,
//  today Sun 9 Nov 2026; plans for November, December and January 2027. January holds
//  Gaji Fulltime and Freelance, Kos (BCA) and a Travelling envelope (Jago); a ticket bought
//  3 Nov is paid early into Travelling, and December sets Rp 2.000.000 aside towards it.
//

import XCTest
import SwiftData
@testable import ExpenseKu

nonisolated final class PlanClearingTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let payday = 1

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: 12)) ?? .distantPast
    }

    private func cycle(_ y: Int, _ m: Int) -> PayCycle {
        PayCycle.containing(date(y, m, 10), payday: payday, calendar: calendar)
    }

    private var today: Date { date(2026, 11, 9) }
    private var november: PayCycle { cycle(2026, 11) }
    private var december: PayCycle { cycle(2026, 12) }
    private var january: PayCycle { cycle(2027, 1) }

    private struct Sample {
        let nov: CyclePlan
        let dec: CyclePlan
        let jan: CyclePlan
        let kos: PlanItem
        let travelling: PlanItem
        let decLine: PlanItem
        let ticket: Expense
        let plans: [CyclePlan]
    }

    @MainActor
    private func sample(in context: ModelContext) throws -> Sample {
        let bca = Account(name: "BCA")
        let jago = Account(name: "Jago")
        [bca, jago].forEach(context.insert)

        func plan(_ cycle: PayCycle) -> CyclePlan {
            let plan = CyclePlan(cycleStart: cycle.start)
            context.insert(plan)
            context.insert(IncomeLine(name: "Gaji Fulltime", amount: 15_250_000, plan: plan))
            return plan
        }
        let nov = plan(november), dec = plan(december), jan = plan(january)
        context.insert(IncomeLine(name: "Freelance", amount: 2_400_000, plan: jan))

        let kos = PlanItem(name: "Kos", amount: 2_200_000, plan: jan, account: bca)
        let travelling = PlanItem(name: "Travelling", amount: 3_000_000, kind: .envelope, plan: jan, account: jago)
        [kos, travelling].forEach(context.insert)
        context.insert(TransferLine(account: bca, adjustment: 50_000, plan: jan))

        let decLine = PlanItem(name: "Travelling", amount: 2_000_000, kind: .setAside, plan: dec, account: jago)
        context.insert(decLine)
        decLine.setAsideTarget = travelling

        let ticket = Expense(amount: 1_200_000, date: date(2026, 11, 3), note: "Tiket kereta")
        context.insert(ticket)
        ticket.envelope = travelling
        try context.save()

        return Sample(nov: nov, dec: dec, jan: jan, kos: kos, travelling: travelling, decLine: decLine,
                      ticket: ticket, plans: [nov, dec, jan])
    }

    // MARK: - §4.1 Only an upcoming cycle with a plan

    @MainActor
    func testOnlyAnUpcomingCycleWithAPlanCanBeCleared() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)

        XCTAssertTrue(PlanClearing.canClear(s.jan, cycle: january, today: today, payday: payday, calendar: calendar))
        XCTAssertTrue(PlanClearing.canClear(s.dec, cycle: december, today: today, payday: payday, calendar: calendar))
        XCTAssertFalse(PlanClearing.canClear(s.nov, cycle: november, today: today, payday: payday, calendar: calendar))
        XCTAssertFalse(PlanClearing.canClear(nil, cycle: cycle(2027, 2), today: today, payday: payday, calendar: calendar))
        XCTAssertFalse(PlanClearing.canClear(s.nov, cycle: cycle(2026, 10), today: today, payday: payday, calendar: calendar))
    }

    // MARK: - §4.2 The confirmation

    func testTitleNamesTheMonth() {
        XCTAssertEqual(PlanClearing.title(month: "January"), "Clear January\u{2019}s plan?")
    }

    @MainActor
    func testReachCountsItsPartsAndEveryLinkFromOutside() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)

        let reach = PlanClearing.reach(of: s.jan, payday: payday, calendar: calendar)

        XCTAssertEqual(reach, PlanClearing.Reach(items: 2, incomeLines: 2, paidEarly: 1, done: 0,
                                                 setAsides: 1, setAsideMonths: ["December"]))
    }

    func testMessageWithLinksMatchesTheApprovedAlert() {
        let reach = PlanClearing.Reach(items: 14, incomeLines: 2, paidEarly: 1, setAsides: 1,
                                       setAsideMonths: ["December"])

        XCTAssertEqual(PlanClearing.message(reach),
                       "14 items and 2 income lines will be deleted. 1 expense paid early and 1 set-aside "
                       + "from December will lose their place in it. Expenses are kept.")
    }

    func testMessageWithoutLinksIsOneSentence() {
        let reach = PlanClearing.Reach(items: 14, incomeLines: 2)

        XCTAssertEqual(PlanClearing.message(reach), "14 items and 2 income lines will be deleted.")
    }

    /// The count matches the plan's own "PLAN · 14 ITEMS" header; the folded rows are
    /// named apart, in the section's own words.
    func testDormantRowsAreCountedApartFromItems() {
        XCTAssertEqual(PlanClearing.message(.init(items: 14, dormant: 11, incomeLines: 2)),
                       "14 items, 11 rows from last cycle and 2 income lines will be deleted.")
    }

    @MainActor
    func testReachSplitsOffDormantRows() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let dormant = PlanItem(name: "Liburan Saving", amount: 0, plan: s.jan)
        context.insert(dormant)
        dormant.carriedOver = true
        try context.save()

        let reach = PlanClearing.reach(of: s.jan, payday: payday, calendar: calendar)

        XCTAssertEqual(reach.items, 2)
        XCTAssertEqual(reach.dormant, 1)
    }

    func testZeroPartsAreDroppedAndAnEmptyPlanSaysSo() {
        XCTAssertEqual(PlanClearing.message(.init(incomeLines: 1)), "1 income line will be deleted.")
        XCTAssertEqual(PlanClearing.message(.init()), "The plan will be deleted.")
    }

    func testOneLinkIsSingularAndSetAsidesFromSeveralMonthsAreEarlierCycles() {
        XCTAssertEqual(PlanClearing.message(.init(items: 3, done: 1)),
                       "3 items will be deleted. 1 expense marked done will lose its place in it. Expenses are kept.")
        XCTAssertEqual(PlanClearing.message(.init(items: 3, setAsides: 2, setAsideMonths: ["November", "December"])),
                       "3 items will be deleted. 2 set-asides from earlier cycles will lose their place in it.")
    }

    @MainActor
    func testDoneExpensesAreCountedOnce() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let paid = Expense(amount: 2_200_000, date: date(2026, 11, 8), note: "Kos")
        context.insert(paid)
        paid.planItem = s.kos
        try context.save()

        XCTAssertEqual(PlanClearing.reach(of: s.jan, payday: payday, calendar: calendar).done, 1)
    }

    // MARK: - §4.3 What clearing does

    @MainActor
    func testClearingDeletesThePlanAndItsPartsButKeepsEveryExpense() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)

        context.delete(s.jan)
        try context.save()

        let plans = try context.fetch(FetchDescriptor<CyclePlan>())
        XCTAssertNil(PlanLookup.plan(for: january, in: plans))
        XCTAssertEqual(try context.fetch(FetchDescriptor<IncomeLine>()).count, 2)
        XCTAssertEqual(try context.fetch(FetchDescriptor<TransferLine>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<PlanItem>()).map(\.name), ["Travelling"])
        XCTAssertEqual(try context.fetch(FetchDescriptor<Expense>()).count, 1)
        XCTAssertNil(s.ticket.envelope)
    }

    @MainActor
    func testAnEarlierSetAsideStaysWithNoTarget() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)

        context.delete(s.jan)
        try context.save()

        XCTAssertEqual(s.decLine.plan?.persistentModelID, s.dec.persistentModelID)
        XCTAssertNil(s.decLine.setAsideTarget)
        XCTAssertEqual(PlanContents(plan: s.dec, cycle: december, cycleExpenses: []).totals.totalCost, 2_000_000)
    }

    // MARK: - §4.4 A cycle with no plan

    @MainActor
    func testCopyFromNamesTheLatestEarlierPlanSkippingGaps() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let remaining = [s.nov, s.dec]

        let source = PlanLookup.source(before: cycle(2027, 3), in: remaining)

        XCTAssertEqual(source?.persistentModelID, s.dec.persistentModelID)
        XCTAssertEqual(LookBackCopy.month(of: PayCycle.containing(s.dec.cycleStart, payday: payday,
                                                                  calendar: calendar), calendar: calendar),
                       "December")
    }

    @MainActor
    func testCopyFromIsTodaysCarryOverRunByTheButton() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        context.delete(s.jan)
        try context.save()

        let copied = PlanCarryOver.makePlan(for: january, from: [s.nov, s.dec], in: context)

        XCTAssertEqual(copied?.copiedFromCycleStart, s.dec.cycleStart)
        XCTAssertEqual(copied?.incomeLines?.count, 1)
        XCTAssertEqual(copied?.items?.count, 0, "December's only item is a set-aside, which is never copied")
    }

    @MainActor
    func testACycleThatHasAPlanIsNeverCopiedOver() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)

        XCTAssertNil(PlanCarryOver.makePlan(for: january, from: s.plans, in: context))
    }

    func testNoPlanMessages() {
        XCTAssertEqual(PlanCopy.noPlanMessage(copyFrom: "December"),
                       "Copy December\u{2019}s plan and adjust it, or start from nothing.")
        XCTAssertEqual(PlanCopy.noPlanMessage(copyFrom: nil),
                       "Start one for this cycle. Every cycle after it can copy it in one tap.")
    }
}
