//
//  PaidEarlyTests.swift
//  ExpenseKuTests
//
//  Flow S (docs/prd/envelope-assignment.md §4.10, ADR-0009), against the PRD's own sample
//  (§7.1): payday 25, today 14 Oct 2026. October's plan has Hidup and Kebutuhan Kos;
//  November's, carried over, adds Travelling. The train ticket is dated 14 Oct and paid
//  early into November's Travelling.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class PaidEarlyTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let payday = 25

    private func date(_ m: Int, _ d: Int, year: Int = 2026, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: m, day: d, hour: hour)) ?? .distantPast
    }

    private var now: Date { date(10, 14, hour: 21) }
    private func cycle(_ m: Int, _ d: Int, year: Int = 2026) -> PayCycle {
        PayCycle.containing(date(m, d, year: year), payday: payday, calendar: calendar)
    }
    private var october: PayCycle { cycle(10, 1) }
    private var november: PayCycle { cycle(11, 1) }

    private struct Sample {
        let octPlan: CyclePlan
        let novPlan: CyclePlan
        let hidup: PlanItem
        let travelling: PlanItem
        let makan: Category
        let seeded: [Expense]
        let ticket: Expense
        var plans: [CyclePlan] { [octPlan, novPlan] }
        var october: [Expense] { seeded + [ticket] }
    }

    @MainActor
    private func sample(in context: ModelContext) throws -> Sample {
        let names = ["Makan", "Bensin", "E-money", "Tisu", "Sabun", "Galon", "Transport"]
        let categories = Dictionary(uniqueKeysWithValues: names.map { ($0, Category(name: $0)) })
        categories.values.forEach(context.insert)
        func claimed(_ names: [String]) -> [Category] { names.compactMap { categories[$0] } }

        let octPlan = CyclePlan(cycleStart: date(9, 25))
        context.insert(octPlan)
        let hidup = PlanItem(name: "Hidup (Makan, bensin, emoney saldo)", amount: 938_300, kind: .envelope,
                             plan: octPlan, envelopeCategories: claimed(["Makan", "Bensin", "E-money"]))
        let kos = PlanItem(name: "Kebutuhan Kos di Jkt (Tisu, sabun, galon)", amount: 193_900, kind: .envelope,
                           plan: octPlan, envelopeCategories: claimed(["Tisu", "Sabun", "Galon"]))
        [hidup, kos].forEach(context.insert)

        let novPlan = try XCTUnwrap(PlanCarryOver.makePlan(for: november, from: [octPlan], in: context))
        let travelling = PlanItem(name: "Travelling", amount: 2_000_000, kind: .envelope, plan: novPlan)
        context.insert(travelling)

        let seeded = [("Makan", Decimal(420_000)), ("Bensin", 191_400), ("E-money", 100_000)].map {
            Expense(amount: $0.1, date: date(9, 28), category: categories[$0.0])
        }
        let ticket = Expense(amount: 1_200_000, date: date(10, 14, hour: 9), note: "Tiket KAI ke Jakarta",
                             category: categories["Transport"])
        (seeded + [ticket]).forEach(context.insert)
        EnvelopeChoice.envelope(travelling.persistentModelID).apply(to: ticket, envelopes: [travelling])
        try context.save()

        return Sample(octPlan: octPlan, novPlan: novPlan, hidup: hidup, travelling: travelling,
                      makan: try XCTUnwrap(categories["Makan"]), seeded: seeded, ticket: ticket)
    }

    private func progress(of envelope: PlanItem, in plan: CyclePlan, cycle: PayCycle,
                          expenses: [Expense]) throws -> EnvelopeProgress {
        let all = EnvelopeSpend.progress(envelopes: EnvelopeOffer.activeEnvelopes(of: plan),
                                         cycleExpenses: expenses, cycle: cycle)
        return try XCTUnwrap(all.first { $0.itemID == envelope.persistentModelID })
    }

    private func offer(_ cycle: PayCycle, _ plans: [CyclePlan],
                       keeping choice: EnvelopeChoice = .byCategory) -> EnvelopeOffer {
        EnvelopeOffer(cycle: cycle, plans: plans, payday: payday, calendar: calendar, now: now, keeping: choice)
    }

    // MARK: - §4.10.1 Where it counts

    /// November's Travelling counts the ticket though November's ledger has none of it.
    @MainActor
    func testTheLaterEnvelopeCountsAPaidEarlyExpense() throws {
        let s = try sample(in: try makeInMemoryContext())
        let travelling = try progress(of: s.travelling, in: s.novPlan, cycle: november, expenses: [])

        XCTAssertEqual(travelling.spent, 1_200_000)
        XCTAssertEqual(travelling.paidEarly, 1_200_000)
        XCTAssertEqual(travelling.remainderText, "Rp\u{00A0}800.000 left")
    }

    /// In October the ticket is listed and totalled but counts in no envelope, and the
    /// split puts it Outside plan, tagged "Travelling · Nov".
    @MainActor
    func testInItsOwnCycleItIsOutsidePlanAndTagged() throws {
        let s = try sample(in: try makeInMemoryContext())
        let origins = PlanOrigins(plans: s.plans, payday: payday, calendar: calendar)

        XCTAssertNil(origins.claims(for: october).envelope(for: s.ticket))
        let origin = try XCTUnwrap(origins.origin(of: s.ticket))
        guard case .paidEarly(let name, let label) = origin else { return XCTFail("\(origin)") }
        XCTAssertEqual(name, "Travelling")
        XCTAssertEqual(label.short, "Nov")
        XCTAssertEqual(label.long, "November")
        XCTAssertFalse(origin.isFromPlan)

        let split = origins.split(s.october, in: october)
        XCTAssertEqual(split.outsidePlan, 1_200_000)
        XCTAssertEqual(split.fromPlan, 711_400)
        XCTAssertEqual(origins.expenses(s.october, in: october, matching: .outsidePlan), [s.ticket])
        XCTAssertFalse(origins.expenses(s.october, in: october, matching: .fromPlan).contains(s.ticket))
        XCTAssertEqual(origins.split(s.october).outsidePlan, 1_200_000, "Insights judges each by its own cycle")
    }

    /// **Counted once.** A Makan paid early leaves October's Hidup alone, though Hidup
    /// claims Makan.
    @MainActor
    func testPaidEarlyNeverFallsBackToItsCategoryClaim() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let bekal = Expense(amount: 60_000, date: date(10, 13), note: "Bekal kereta", category: s.makan)
        context.insert(bekal)
        bekal.envelope = s.travelling
        try context.save()

        let hidup = try progress(of: s.hidup, in: s.octPlan, cycle: october, expenses: s.october + [bekal])
        XCTAssertEqual(hidup.remainderText, "Rp\u{00A0}226.900 left")
        let travelling = try progress(of: s.travelling, in: s.novPlan, cycle: november, expenses: [])
        XCTAssertEqual(travelling.spent, 1_260_000)
    }

    // MARK: - §4.10.2 What is offered

    /// Own cycle first, then each later cycle with a plan that has not ended, oldest first.
    /// Earlier plans are never offered, and offering creates nothing.
    @MainActor
    func testTheOfferAddsLaterCyclesWithAPlanThatHasNotEnded() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let september = CyclePlan(cycleStart: date(8, 25))
        context.insert(september)
        context.insert(PlanItem(name: "Lama", amount: 100_000, kind: .envelope, plan: september))
        try context.save()
        let plans = [september] + s.plans

        let octOffer = offer(october, plans)
        XCTAssertEqual(octOffer.sections.map(\.isPaidEarly), [false, true])
        XCTAssertEqual(octOffer.sections.map { $0.cycle.start }, [october.start, november.start])
        XCTAssertEqual(octOffer.sections[1].envelopes.map(\.name),
                       ["Travelling", "Hidup (Makan, bensin, emoney saldo)", "Kebutuhan Kos di Jkt (Tisu, sabun, galon)"])
        XCTAssertEqual(octOffer.sections[1].label?.short, "Nov")

        XCTAssertEqual(offer(november, plans).sections.map(\.isPaidEarly), [false], "never backward")
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CyclePlan>()), 3, "no December plan was made")
    }

    /// A July expense is offered July's envelopes and those of cycles still open — not
    /// August's, which has ended, unless it already sits in one of August's.
    @MainActor
    func testAnEndedLaterCycleIsOfferedOnlyToKeepTheCurrentChoice() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let july = CyclePlan(cycleStart: date(6, 25))
        let august = CyclePlan(cycleStart: date(7, 25))
        [july, august].forEach(context.insert)
        context.insert(PlanItem(name: "Juli", amount: 100_000, kind: .envelope, plan: july))
        let augustTrip = PlanItem(name: "Bandung", amount: 500_000, kind: .envelope, plan: august)
        context.insert(augustTrip)
        try context.save()
        let plans = [july, august] + s.plans

        XCTAssertEqual(offer(cycle(7, 1), plans).sections.map { $0.cycle.start },
                       [cycle(7, 1).start, october.start, november.start])
        let kept = offer(cycle(7, 1), plans, keeping: .envelope(augustTrip.persistentModelID))
        XCTAssertEqual(kept.sections.map { $0.cycle.start },
                       [cycle(7, 1).start, cycle(8, 1).start, october.start, november.start])
    }

    /// With no envelope in its own cycle, an expense can still be moved — into a later one.
    @MainActor
    func testARowCanMoveWhenOnlyALaterCycleHasAnEnvelope() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        s.octPlan.items?.forEach(context.delete)
        try context.save()
        let origins = PlanOrigins(plans: s.plans, payday: payday, calendar: calendar)

        XCTAssertEqual(origins.moveTarget(for: s.seeded[0], now: now), october)
        XCTAssertEqual(offer(october, s.plans).sections.map(\.isPaidEarly), [true])
        XCTAssertNil(PlanOrigins(plans: [s.octPlan], payday: payday, calendar: calendar)
            .moveTarget(for: s.seeded[0], now: now))
    }

    // MARK: - §4.10.3 The editor row

    @MainActor
    func testTheEditorRowNamesTheLaterCycle() throws {
        let s = try sample(in: try makeInMemoryContext())
        let options = EnvelopeOptions(offer: offer(october, s.plans), expenses: s.october)

        XCTAssertEqual(options.value(for: .envelope(s.travelling.persistentModelID), category: nil),
                       EnvelopeRowValue(name: "Travelling", suffix: "· Nov", isChosen: true))
        XCTAssertEqual(options.progress(of: s.travelling)?.remainderText, "Rp\u{00A0}800.000 left",
                       "the picker's remainder counts what was already paid early")
    }

    // MARK: - §4.10.4 Changing the date

    /// Kept while the new date's cycle is not after the envelope's: earlier makes it paid
    /// early, the same cycle an ordinary assignment, later resets it.
    @MainActor
    func testADateChangeKeepsTheAssignmentUntilItPassesTheEnvelopesCycle() throws {
        let s = try sample(in: try makeInMemoryContext())
        let choice = EnvelopeChoice.envelope(s.travelling.persistentModelID)
        func kept(on cycle: PayCycle) -> EnvelopeChoice {
            choice.kept(among: offer(cycle, s.plans, keeping: choice).envelopes)
        }

        XCTAssertEqual(kept(on: cycle(9, 1)), choice, "September is before November too")
        XCTAssertEqual(kept(on: october), choice)
        XCTAssertEqual(kept(on: november), choice)
        XCTAssertEqual(kept(on: cycle(12, 1)), .byCategory)
    }

    // MARK: - §4.10.5 The tag's month

    func testTheTagAddsTheYearATwelvemonthAhead() {
        XCTAssertEqual(PaidEarlyLabel(target: november, from: october, calendar: calendar).short, "Nov")
        XCTAssertEqual(PaidEarlyLabel(target: cycle(1, 1, year: 2027), from: october, calendar: calendar).short, "Jan")
        let farAhead = PaidEarlyLabel(target: cycle(11, 1, year: 2027), from: october, calendar: calendar)
        XCTAssertEqual(farAhead.short, "Nov 2027")
        XCTAssertEqual(farAhead.long, "November 2027")
    }

    // MARK: - §4.10.6 The caption (replaced by set-aside.md §4.6, decision 15)

    @MainActor
    func testTheCaptionNamesTheMonthOnlyWhenEveryExpenseComesFromOneCycle() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let travelling = try progress(of: s.travelling, in: s.novPlan, cycle: november, expenses: [])
        XCTAssertEqual(travelling.fromEarlierCaption(payday: payday, calendar: calendar),
                       "Rp\u{00A0}1.200.000 from October")
        XCTAssertEqual(travelling.ownShareCaption(cycle: november, calendar: calendar),
                       "Rp\u{00A0}800.000 from November")

        let deposit = Expense(amount: 300_000, date: date(9, 20), note: "DP hotel")
        context.insert(deposit)
        deposit.envelope = s.travelling
        try context.save()
        let both = try progress(of: s.travelling, in: s.novPlan, cycle: november, expenses: [])
        XCTAssertEqual(both.fromEarlierCaption(payday: payday, calendar: calendar), "Rp\u{00A0}1.500.000 from earlier")

        let hidup = try progress(of: s.hidup, in: s.octPlan, cycle: october, expenses: s.october)
        XCTAssertNil(hidup.fromEarlierCaption(payday: payday, calendar: calendar))
        XCTAssertNil(hidup.ownShareCaption(cycle: october, calendar: calendar))
    }

    // MARK: - §4.10.8 Move expenses here…

    /// Opened on 14 Oct for November's Travelling: November has nothing yet; October's
    /// expenses follow, newest first; September has ended and is not offered.
    @MainActor
    func testGatheringIntoALaterEnvelopeOffersTodaysCycleToo() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let old = Expense(amount: 50_000, date: date(9, 10), note: "September")
        context.insert(old)
        EnvelopeChoice.byCategory.apply(to: s.ticket, envelopes: [])
        try context.save()
        let claims = EnvelopeClaims(envelopes: EnvelopeOffer.activeEnvelopes(of: s.novPlan), cycle: november)

        let sections = EnvelopeGather.sections(for: s.travelling, claims: claims, expenses: s.october + [old],
                                               payday: payday, calendar: calendar, now: now)
        XCTAssertEqual(sections.map(\.isPaidEarly), [true])
        XCTAssertEqual(sections.first?.cycle, october)
        XCTAssertEqual(sections.first?.expenses.first, s.ticket)
        XCTAssertEqual(sections.first?.expenses.count, 4)
        XCTAssertEqual(EnvelopeGather.earliestStart(for: november, payday: payday, calendar: calendar, now: now),
                       october.start)
    }

    // MARK: - §4.10.9 Deleting and carrying over

    @MainActor
    func testDeletingTheEnvelopeReturnsThePaidEarlyExpenseToItsOwnCycle() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        XCTAssertEqual(s.travelling.assignedExpenses?.count, 1, "the confirmation counts it")

        context.delete(s.travelling)
        try context.save()

        XCTAssertNil(s.ticket.envelope)
        let origins = PlanOrigins(plans: s.plans, payday: payday, calendar: calendar)
        XCTAssertNil(origins.origin(of: s.ticket), "Transport is claimed by no October envelope")
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 4)
    }

    /// Carry-over copies November's Travelling into December empty; an envelope holding
    /// paid-early money is never dormant.
    @MainActor
    func testCarryOverLeavesThePaidEarlyExpenseWhereItIs() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        s.travelling.amount = 0
        s.travelling.carriedOver = true
        XCTAssertFalse(PlanDormancy.isDormant(s.travelling))

        let december = try XCTUnwrap(PlanCarryOver.makePlan(for: cycle(12, 1), from: s.plans, in: context))
        let copy = try XCTUnwrap(december.items?.first { $0.name == "Travelling" })
        XCTAssertEqual(copy.assignedExpenses ?? [], [])
        XCTAssertEqual(s.ticket.envelope, s.travelling)
    }
}
