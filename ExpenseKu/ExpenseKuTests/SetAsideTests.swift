//
//  SetAsideTests.swift
//  ExpenseKuTests
//
//  Flow W (docs/prd/set-aside.md), one test per rule, against the PRD's sample (§7):
//  payday 25, Gaji Rp 18.000.000, Kos Rp 2.200.000 (BCA) and Hidup Rp 3.000.000 every
//  cycle; Rp 5.000.000 set aside in October (moved) and Rp 7.000.000 in November (not)
//  for December's Rp 20.000.000 Jepang (Jago); a Rp 6.500.000 ticket bought 2 Oct, paid
//  early into Jepang.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class SetAsideTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let payday = 25

    private func date(_ m: Int, _ d: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: m, day: d, hour: hour)) ?? .distantPast
    }

    private func cycle(_ m: Int, _ d: Int) -> PayCycle {
        PayCycle.containing(date(m, d), payday: payday, calendar: calendar)
    }
    private var october: PayCycle { cycle(10, 1) }
    private var november: PayCycle { cycle(11, 1) }
    private var december: PayCycle { cycle(12, 1) }

    private struct Sample {
        let oct: CyclePlan
        let nov: CyclePlan
        let dec: CyclePlan
        let jepang: PlanItem
        let octLine: PlanItem
        let novLine: PlanItem
        let travel: CategoryGroup
        let ticket: Expense
        let octExpenses: [Expense]
    }

    @MainActor
    private func sample(in context: ModelContext, novAmount: Decimal = 7_000_000) throws -> Sample {
        let housing = CategoryGroup(name: "Housing & Living")
        let travel = CategoryGroup(name: "Transportation & Travel")
        [housing, travel].forEach(context.insert)
        let sewa = Category(name: "Sewa")
        let makan = Category(name: "Makan")
        let flight = Category(name: "Flight")
        [sewa, makan, flight].forEach(context.insert)
        sewa.group = housing
        makan.group = housing
        flight.group = travel
        let bca = Account(name: "BCA")
        let jago = Account(name: "Jago")
        [bca, jago].forEach(context.insert)

        func plan(_ cycle: PayCycle) -> CyclePlan {
            let plan = CyclePlan(cycleStart: cycle.start)
            context.insert(plan)
            context.insert(IncomeLine(name: "Gaji", amount: 18_000_000, plan: plan))
            context.insert(PlanItem(name: "Kos", amount: 2_200_000, plan: plan, category: sewa, account: bca))
            context.insert(PlanItem(name: "Hidup", amount: 3_000_000, kind: .envelope, plan: plan,
                                    envelopeCategories: [makan]))
            return plan
        }
        let oct = plan(october), nov = plan(november), dec = plan(december)

        let jepang = PlanItem(name: "Jepang", amount: 20_000_000, kind: .envelope, plan: dec,
                              account: jago, envelopeCategories: [flight])
        context.insert(jepang)

        func line(_ plan: CyclePlan, _ amount: Decimal, moved: Bool) -> PlanItem {
            let line = PlanItem(name: "Jepang", amount: amount, kind: .setAside, plan: plan, account: jago)
            context.insert(line)
            line.setAsideTarget = jepang
            line.isSetAsideMoved = moved
            return line
        }
        let octLine = line(oct, 5_000_000, moved: true)
        let novLine = line(nov, novAmount, moved: false)

        let ticket = Expense(amount: 6_500_000, date: date(10, 2), note: "Tiket Jakarta–Tokyo")
        context.insert(ticket)
        ticket.envelope = jepang
        try context.save()

        return Sample(oct: oct, nov: nov, dec: dec, jepang: jepang, octLine: octLine, novLine: novLine,
                      travel: travel, ticket: ticket, octExpenses: [ticket])
    }

    private func contents(_ plan: CyclePlan, _ cycle: PayCycle, _ expenses: [Expense] = []) -> PlanContents {
        PlanContents(plan: plan, cycle: cycle, cycleExpenses: expenses)
    }

    // MARK: - §4.1 Its own plan

    /// October: the line is an ordinary item, in Total cost, so Sisa falls by it with no
    /// reconciling row of its own.
    @MainActor
    func testOctobersLineIsInTotalCostAndSisaFallsByIt() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let totals = contents(s.oct, october, s.octExpenses).totals

        XCTAssertEqual(totals.totalCost, 10_200_000)
        XCTAssertEqual(totals.paidEarly.outgoing, 6_500_000)
        XCTAssertEqual(totals.setAside.incoming, 0)
        XCTAssertNil(totals.setAside.incomingLabel(payday: payday, calendar: calendar))
        XCTAssertEqual(totals.sisa, 1_300_000)
    }

    /// November: Sisa 18jt − 12,2jt.
    @MainActor
    func testNovembersSisa() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        XCTAssertEqual(contents(s.nov, november).totals.sisa, 5_800_000)
    }

    // MARK: - §4.5 Money between the two plans

    /// December: "Set aside earlier +12jt" beside "Paid early in October +6,5jt".
    @MainActor
    func testDecemberIsCreditedWithEverySetAsideLine() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let totals = contents(s.dec, december).totals

        XCTAssertEqual(totals.totalCost, 25_200_000, "Total cost stays Σ planned")
        XCTAssertEqual(totals.paidEarly.incoming, 6_500_000)
        XCTAssertEqual(totals.setAside.incoming, 12_000_000)
        XCTAssertEqual(totals.setAside.incomingLabel(payday: payday, calendar: calendar), "Set aside earlier")
        XCTAssertEqual(totals.sisa, 11_300_000)
    }

    @MainActor
    func testOneSourceCycleIsNamed() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        context.delete(s.novLine)
        try context.save()
        let totals = contents(s.dec, december).totals

        XCTAssertEqual(totals.setAside.incoming, 5_000_000)
        XCTAssertEqual(totals.setAside.incomingLabel(payday: payday, calendar: calendar), "Set aside in October")
    }

    /// Decision 4: the tick moves no figure.
    @MainActor
    func testTickingMovesNoFigure() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let before = (contents(s.oct, october, s.octExpenses).totals.sisa, contents(s.dec, december).totals.sisa)
        s.octLine.isSetAsideMoved = false
        s.novLine.isSetAsideMoved = true
        try context.save()
        let after = (contents(s.oct, october, s.octExpenses).totals.sisa, contents(s.dec, december).totals.sisa)

        XCTAssertEqual(before.0, after.0)
        XCTAssertEqual(before.1, after.1)
    }

    /// Decision 6, *owner override*: no cap. 5jt + 16jt for a 20jt Jepang credits 21jt.
    @MainActor
    func testTheCreditIsNotCapped() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context, novAmount: 16_000_000)
        let dec = contents(s.dec, december)

        XCTAssertEqual(dec.totals.setAside.incoming, 21_000_000)
        XCTAssertEqual(dec.totals.sisa, 18_000_000 - 25_200_000 + 6_500_000 + 21_000_000)
        XCTAssertEqual(dec.envelope(for: s.jepang)?.ownShareCaption(cycle: december, calendar: calendar),
                       "Rp\u{00A0}0 from December")
        XCTAssertEqual(dec.transfers.first { $0.accountName == "Jago" }?.transfer, 0)
    }

    /// D8: paid early keeps its own cap, whatever was set aside.
    @MainActor
    func testPaidEarlysCapIgnoresSetAside() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        s.ticket.amount = 25_000_000
        try context.save()

        XCTAssertEqual(contents(s.dec, december).totals.paidEarly.incoming, 20_000_000)
        XCTAssertEqual(contents(s.dec, december).totals.setAside.incoming, 12_000_000)
    }

    // MARK: - §4.6 The target's cycle

    /// Decisions 14 and 16: one line for everything from earlier, and this cycle's share
    /// under the planned amount. The bar is spending only.
    @MainActor
    func testJepangsRowSaysWhatCameFromEarlierAndWhatDecemberStillPutsIn() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let jepang = try XCTUnwrap(contents(s.dec, december).envelope(for: s.jepang))

        XCTAssertEqual(jepang.spent, 6_500_000, "the ticket is spent; the set-aside money is not")
        XCTAssertEqual(jepang.remainderText, "Rp\u{00A0}13.500.000 left")
        XCTAssertEqual(jepang.fromEarlierCaption(payday: payday, calendar: calendar),
                       "Rp\u{00A0}18.500.000 from earlier")
        XCTAssertEqual(jepang.ownShareCaption(cycle: december, calendar: calendar),
                       "Rp\u{00A0}1.500.000 from December")
    }

    /// Paid early and set aside both from October name the month.
    @MainActor
    func testAllFromOneCycleNamesIt() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        context.delete(s.novLine)
        try context.save()
        let jepang = try XCTUnwrap(contents(s.dec, december).envelope(for: s.jepang))

        XCTAssertEqual(jepang.fromEarlierCaption(payday: payday, calendar: calendar),
                       "Rp\u{00A0}11.500.000 from October")
    }

    /// Decision 7: ke Jago counts Jepang net, and says why on one line.
    @MainActor
    func testDecembersTransferLineIsNet() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let jago = try XCTUnwrap(contents(s.dec, december).transfers.first { $0.accountName == "Jago" })

        XCTAssertEqual(jago.transfer, 1_500_000)
        XCTAssertEqual(jago.creditText, "Rp\u{00A0}6.500.000 paid early · Rp\u{00A0}12.000.000 set aside")
    }

    @MainActor
    func testASetAsideAloneNamesItsEnvelope() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        s.ticket.envelope = nil
        try context.save()
        let jago = try XCTUnwrap(contents(s.dec, december).transfers.first { $0.accountName == "Jago" })

        XCTAssertEqual(jago.transfer, 8_000_000)
        XCTAssertEqual(jago.creditText, "Rp\u{00A0}12.000.000 set aside into Jepang")
    }

    /// October's own line joins its Account's transfer line in full.
    @MainActor
    func testOctobersLineJoinsKeJago() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let jago = try XCTUnwrap(contents(s.oct, october, s.octExpenses).transfers.first { $0.accountName == "Jago" })

        XCTAssertEqual(jago.transfer, 5_000_000)
        XCTAssertNil(jago.creditText)
    }

    /// Decision 12: October counts it in Jepang's Group; December counts Jepang net.
    @MainActor
    func testGroupSharesFollowTheTarget() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let oct = contents(s.oct, october, s.octExpenses).groupShares
        let dec = contents(s.dec, december).groupShares

        XCTAssertEqual(oct.first { $0.groupName == s.travel.name }?.planned, 5_000_000)
        XCTAssertEqual(dec.first { $0.groupName == s.travel.name }?.planned, 1_500_000)
    }

    // MARK: - §4.4 Ticking it

    @MainActor
    func testTheCheckIsAOneItemMenuAndNeverFunded() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)

        XCTAssertEqual(DoneCheckState.state(for: s.novLine), .setAside)
        XCTAssertEqual(DoneCheckTap.of(s.novLine), .menu([.setAsideMoved(account: "Jago", target: "Jepang")]))
        XCTAssertEqual(FundMenuEntry.setAsideMoved(account: "Jago", target: "Jepang").title, "Moved to Jago")
        XCTAssertEqual(FundMenuEntry.setAsideMoved(account: nil, target: "Jepang").title, "Set aside")
        XCTAssertEqual(FundMenuEntry.setAsideMoved(account: nil, target: "Jepang").setAsideMovedValue, true)

        XCTAssertEqual(DoneCheckState.state(for: s.octLine), .setAsideMoved)
        XCTAssertEqual(DoneCheckTap.of(s.octLine), .menu([.setAsideUndo(hasAccount: true)]))
        XCTAssertEqual(FundMenuEntry.setAsideUndo(hasAccount: true).title, "Not moved yet")
        XCTAssertEqual(FundMenuEntry.setAsideUndo(hasAccount: false).title, "Not set aside yet")
        XCTAssertEqual(FundMenuEntry.setAsideUndo(hasAccount: false).setAsideMovedValue, false)
        XCTAssertNil(FundMenuEntry.setAsideUndo(hasAccount: false).fundedValue)

        s.novLine.isFunded = true
        XCTAssertEqual(PlanItemState.of(s.novLine), .todo, "never Funded, whatever the flag says")
        XCTAssertTrue(contents(s.nov, november).funded.isEmpty)
    }

    /// D5: the Status sort puts ◯ in Todo and ✓ in Done, and the header counts it done.
    @MainActor
    func testStatusSortAndDoneCount() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let oct = contents(s.oct, october, s.octExpenses)
        let sections = PlanSections.sections(oct.activeItems, by: .status, cycle: october, calendar: calendar)

        XCTAssertTrue(sections.first { $0.title?.hasPrefix("Done") == true }?.items.contains(s.octLine) == true)
        XCTAssertEqual(oct.doneCount, 1)
        let nov = PlanSections.sections(contents(s.nov, november).activeItems, by: .status,
                                        cycle: november, calendar: calendar)
        XCTAssertTrue(nov.first { $0.title?.hasPrefix("Todo") == true }?.items.contains(s.novLine) == true)
    }

    // MARK: - §4.8 Carry-over

    @MainActor
    func testCarryOverNeverCopiesASetAsideLine() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        context.delete(s.dec)
        try context.save()
        let made = try XCTUnwrap(PlanCarryOver.makePlan(for: december, from: [s.oct, s.nov], in: context))

        XCTAssertFalse((made.items ?? []).contains(where: \.isSetAside))
        XCTAssertEqual(made.copiedItemCount, 2)
    }

    @MainActor
    func testASetAsideLineIsNeverDormant() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        s.octLine.carriedOver = true
        s.octLine.amount = 0
        XCTAssertFalse(PlanDormancy.isDormant(s.octLine))
    }

    // MARK: - §4.9 Losing the target

    @MainActor
    func testDeletingTheEnvelopeKeepsTheLinesDebitingTheirOwnPlans() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        context.delete(s.jepang)
        try context.save()

        XCTAssertNil(s.octLine.setAsideTarget)
        XCTAssertNil(SetAside.target(of: s.octLine))
        XCTAssertEqual(contents(s.oct, october, s.octExpenses).totals.totalCost, 10_200_000)
        XCTAssertEqual(contents(s.oct, october, s.octExpenses).totals.sisa, 7_800_000,
                       "the ticket counts by category again; the line still debits")
    }

    /// D10: a target in the same or an earlier cycle, or one that is no longer an
    /// envelope, credits nobody.
    @MainActor
    func testAnInvalidTargetIsIgnored() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let novHidup = try XCTUnwrap(s.nov.items?.first { $0.name == "Hidup" })
        s.novLine.setAsideTarget = novHidup
        XCTAssertNil(SetAside.target(of: s.novLine), "same cycle")
        let octHidup = try XCTUnwrap(s.oct.items?.first { $0.name == "Hidup" })
        s.novLine.setAsideTarget = octHidup
        XCTAssertNil(SetAside.target(of: s.novLine), "earlier cycle")
        s.novLine.setAsideTarget = s.jepang
        s.jepang.kind = .fixed
        XCTAssertNil(SetAside.target(of: s.novLine), "no longer an envelope")
        try context.save()
        XCTAssertEqual(contents(s.dec, december).totals.setAside.incoming, 0)
    }

    @MainActor
    func testTheDeleteConfirmationNamesTheSetAsides() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let lines = SetAside.sources(into: s.jepang)
        let months = SetAside.months(of: lines, payday: payday, calendar: calendar)

        XCTAssertEqual(months, ["October", "November"])
        XCTAssertEqual(PlanCopy.deleteItemBody(amount: nil, date: nil, assignedCount: 1,
                                               setAsideCount: lines.count, setAsideMonths: months),
                       "1 expense assigned to it stays in your ledger and goes back to counting by category. "
                       + "2 set-asides in October and November will lose their envelope.")
        XCTAssertEqual(PlanCopy.deleteItemBody(amount: nil, date: nil, setAsideCount: 1, setAsideMonths: ["October"]),
                       "1 set-aside in October will lose its envelope.")
    }

    // MARK: - §4.2 The editor's targets

    @MainActor
    func testTheForPickerOffersOnlyLaterPlans() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let sections = SetAside.offer(for: s.oct, plans: [s.oct, s.nov, s.dec], keeping: nil,
                                      payday: payday, calendar: calendar, now: date(10, 17))

        XCTAssertEqual(sections.map(\.cycle), [november, december])
        XCTAssertEqual(sections.last?.envelopes.map(\.name), ["Jepang", "Hidup"])
        XCTAssertEqual(SetAside.label(of: s.octLine, payday: payday, calendar: calendar)?.short, "Dec")
        XCTAssertTrue(SetAside.offer(for: s.dec, plans: [s.oct, s.nov, s.dec], keeping: nil,
                                     payday: payday, calendar: calendar, now: date(10, 17)).isEmpty)
    }

    // MARK: - §4.7 Envelope detail

    @MainActor
    func testTheDetailListsTheSetAsideLinesOldestFirst() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let envelopes = EnvelopeOffer.activeEnvelopes(of: s.dec)
        let detail = EnvelopeDetail(envelope: s.jepang, claims: EnvelopeClaims(envelopes: envelopes, cycle: december),
                                    cycleExpenses: [], payday: payday, calendar: calendar)

        XCTAssertEqual(detail.setAsideLines, [s.octLine, s.novLine])
        XCTAssertEqual(detail.total, 6_500_000, "money set aside is not spending")
    }
}
