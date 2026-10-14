//
//  PaidEarlyShiftTests.swift
//  ExpenseKuTests
//
//  Flow U (docs/prd/envelope-assignment.md §4.10.10), against the PRD's sample (§7.1):
//  payday 25, the ticket (14 Oct, Rp 1.200.000) paid early into November's Travelling
//  (Rp 2.000.000, on BCA), income Rp 10.000.000 in both cycles.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class PaidEarlyShiftTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let payday = 25

    private func date(_ m: Int, _ d: Int, year: Int = 2026, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: m, day: d, hour: hour)) ?? .distantPast
    }

    private func cycle(_ m: Int, _ d: Int) -> PayCycle {
        PayCycle.containing(date(m, d), payday: payday, calendar: calendar)
    }
    private var october: PayCycle { cycle(10, 1) }
    private var november: PayCycle { cycle(11, 1) }
    private var december: PayCycle { cycle(12, 1) }

    private struct Sample {
        let octPlan: CyclePlan
        let novPlan: CyclePlan
        let travelling: PlanItem
        let bca: Account
        let ticket: Expense
        let october: [Expense]
    }

    @MainActor
    private func sample(in context: ModelContext, ticketAmount: Decimal = 1_200_000) throws -> Sample {
        let makan = Category(name: "Makan")
        let transport = Category(name: "Transport")
        [makan, transport].forEach(context.insert)
        let bca = Account(name: "BCA")
        context.insert(bca)

        let octPlan = CyclePlan(cycleStart: october.start)
        context.insert(octPlan)
        context.insert(IncomeLine(name: "Gaji", amount: 10_000_000, plan: octPlan))
        context.insert(PlanItem(name: "Hidup", amount: 938_300, kind: .envelope, plan: octPlan,
                                envelopeCategories: [makan]))

        let novPlan = CyclePlan(cycleStart: november.start)
        context.insert(novPlan)
        context.insert(IncomeLine(name: "Gaji", amount: 10_000_000, plan: novPlan))
        context.insert(PlanItem(name: "Hidup", amount: 938_300, kind: .envelope, plan: novPlan,
                                envelopeCategories: [makan]))
        let travelling = PlanItem(name: "Travelling", amount: 2_000_000, kind: .envelope,
                                  plan: novPlan, account: bca)
        context.insert(travelling)

        let lunch = Expense(amount: 50_000, date: date(10, 1), category: makan)
        let ticket = Expense(amount: ticketAmount, date: date(10, 14, hour: 9), note: "Tiket KAI ke Jakarta",
                             category: transport)
        [lunch, ticket].forEach(context.insert)
        ticket.envelope = travelling
        try context.save()

        return Sample(octPlan: octPlan, novPlan: novPlan, travelling: travelling, bca: bca,
                      ticket: ticket, october: [lunch, ticket])
    }

    private func contents(_ plan: CyclePlan?, _ cycle: PayCycle, _ expenses: [Expense]) -> PlanContents {
        PlanContents(plan: plan, cycle: cycle, cycleExpenses: expenses)
    }

    // MARK: - The own cycle

    @MainActor
    func testOctobersSisaFallsByThePaidEarlyTicket() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let totals = contents(s.octPlan, october, s.october).totals

        XCTAssertEqual(totals.totalCost, 938_300, "Total cost stays Σ planned")
        XCTAssertEqual(totals.paidEarly.outgoing, 1_200_000)
        XCTAssertEqual(totals.sisa, 10_000_000 - 938_300 - 1_200_000)
        XCTAssertEqual(totals.paidEarly.outgoingLabel(payday: payday, calendar: calendar), "Paid early for November")
        XCTAssertNil(totals.paidEarly.incomingLabel(payday: payday, calendar: calendar))
    }

    // MARK: - The envelope's cycle

    @MainActor
    func testNovembersSisaRisesByTheTicket() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let november = contents(s.novPlan, november, [])
        let totals = november.totals

        XCTAssertEqual(totals.totalCost, 2_938_300, "Travelling still counts its full plan in Total cost")
        XCTAssertEqual(totals.paidEarly.incoming, 1_200_000)
        XCTAssertEqual(totals.sisa, 10_000_000 - 2_938_300 + 1_200_000)
        XCTAssertEqual(totals.paidEarly.incomingLabel(payday: payday, calendar: calendar), "Paid early in October")
        XCTAssertNil(totals.paidEarly.outgoingLabel(payday: payday, calendar: calendar))
        XCTAssertEqual(november.headline.amount, totals.sisa, "the SISA headline follows")
        XCTAssertEqual(november.envelope(for: s.travelling)?.remainder, 800_000, "the row is unchanged")
    }

    /// 2,5jt paid early into a 2jt Travelling, then 300rb in November: October carries
    /// all 2,5jt, November gains at most 2jt, and drift still reports the whole 800rb
    /// over (*owner override*).
    @MainActor
    func testTheCreditIsCappedAtTheEnvelopeAndDriftKeepsTheWholeOverspend() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context, ticketAmount: 2_500_000)
        let hotel = Expense(amount: 300_000, date: date(10, 27), note: "Hotel")
        context.insert(hotel)
        hotel.envelope = s.travelling
        try context.save()

        let octTotals = contents(s.octPlan, october, s.october).totals
        XCTAssertEqual(octTotals.paidEarly.outgoing, 2_500_000)

        let nov = contents(s.novPlan, november, [hotel])
        XCTAssertEqual(nov.totals.paidEarly.incoming, 2_000_000)
        XCTAssertEqual(nov.envelope(for: s.travelling)?.overspend, 800_000)
        XCTAssertEqual(nov.totals.drift, 800_000)
        XCTAssertEqual(nov.transfers.first?.planned, 0, "ke BCA owes nothing for Travelling")
    }

    // MARK: - Transfers and Group shares

    @MainActor
    func testKeBCACountsTravellingNetAndSaysWhy() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let row = try XCTUnwrap(contents(s.novPlan, november, []).transfers.first)

        XCTAssertEqual(row.accountName, s.bca.name)
        XCTAssertEqual(row.planned, 800_000)
        XCTAssertEqual(row.paidEarlyText, "Rp\u{00A0}1.200.000 paid early into Travelling")
    }

    @MainActor
    func testTwoEnvelopesOnOneAccountDropTheName() throws {
        let context = try makeInMemoryContext()
        let bca = Account(name: "BCA")
        context.insert(bca)
        let row = TransferRow(accountID: bca.persistentModelID, accountName: "BCA", planned: 0,
                              adjustment: 0, hasTransferred: false, allAuto: false,
                              paidEarly: 1_500_000, paidEarlyEnvelopes: ["Travelling", "Kado"])
        XCTAssertEqual(row.paidEarlyText, "Rp\u{00A0}1.500.000 paid early")
    }

    @MainActor
    func testGroupSharesCountTheEnvelopeNet() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let nov = contents(s.novPlan, november, [])
        let shared = nov.groupShares.reduce(Decimal(0)) { $0 + $1.planned }
        XCTAssertEqual(shared, nov.totals.totalCost - 1_200_000)
    }

    // MARK: - When it shows

    @MainActor
    func testNothingPaidEarlyShowsNoRow() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        s.ticket.envelope = nil
        try context.save()

        let oct = contents(s.octPlan, october, s.october).totals
        let nov = contents(s.novPlan, november, []).totals
        XCTAssertEqual(oct.paidEarly, .none)
        XCTAssertEqual(nov.paidEarly, .none)
        XCTAssertEqual(nov.sisa, 10_000_000 - 2_938_300)
        XCTAssertNil(oct.paidEarly.outgoingLabel(payday: payday, calendar: calendar))
    }

    @MainActor
    func testSeveralCyclesDropTheMonth() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let decPlan = CyclePlan(cycleStart: december.start)
        context.insert(decPlan)
        let kado = PlanItem(name: "Kado", amount: 500_000, kind: .envelope, plan: decPlan)
        context.insert(kado)
        let gift = Expense(amount: 200_000, date: date(10, 10), note: "Kado")
        let deposit = Expense(amount: 100_000, date: date(9, 20), note: "DP hotel")
        [gift, deposit].forEach(context.insert)
        gift.envelope = kado
        deposit.envelope = s.travelling
        try context.save()

        let oct = contents(s.octPlan, october, s.october + [gift]).totals
        XCTAssertEqual(oct.paidEarly.outgoing, 1_400_000)
        XCTAssertEqual(oct.paidEarly.outgoingLabel(payday: payday, calendar: calendar), "Paid early for later cycles")

        let nov = contents(s.novPlan, november, []).totals
        XCTAssertEqual(nov.paidEarly.incoming, 1_300_000)
        XCTAssertEqual(nov.paidEarly.incomingLabel(payday: payday, calendar: calendar), "Paid early")
    }

    /// October without a plan has no totals to debit; November still takes its credit.
    @MainActor
    func testAnOwnCycleWithoutAPlanStillCreditsTheEnvelopesCycle() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        XCTAssertEqual(contents(nil, october, s.october).totals.paidEarly, .none)
        XCTAssertEqual(contents(s.novPlan, november, []).totals.paidEarly.incoming, 1_200_000)
    }

    @MainActor
    func testDeletingTheEnvelopeRemovesBothSides() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        context.delete(s.travelling)
        try context.save()

        XCTAssertEqual(contents(s.octPlan, october, s.october).totals.paidEarly.outgoing, 0)
        XCTAssertEqual(contents(s.novPlan, november, []).totals.paidEarly.incoming, 0)
    }
}
