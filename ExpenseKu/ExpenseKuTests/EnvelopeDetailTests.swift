//
//  EnvelopeDetailTests.swift
//  ExpenseKuTests
//
//  Flow T (docs/prd/envelope-detail.md), against the PRD's own samples (§7): payday 25.
//  October 2026 is the `travelling` seed — Hidup by category, a Bandung trip assigned to
//  Travelling, a gift marked No envelope. November 2026 holds a second Travelling, which
//  the train ticket of 14 Oct is paid early into.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class EnvelopeDetailTests: XCTestCase {
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

    private struct Sample {
        let octPlan: CyclePlan
        let novPlan: CyclePlan
        let hidup: PlanItem
        let octTravelling: PlanItem
        let novTravelling: PlanItem
        let categories: [String: Category]
        let seeded: [Expense]
        let trip: [Expense]
        let gift: Expense
        let ticket: Expense
        var october: [Expense] { seeded + trip + [gift, ticket] }
    }

    @MainActor
    private func sample(in context: ModelContext) throws -> Sample {
        let names = ["Makan", "Bensin", "E-money", "Sewa", "Transport", "Pulsa"]
        let categories = Dictionary(uniqueKeysWithValues: names.map { ($0, Category(name: $0)) })
        categories.values.forEach(context.insert)

        let octPlan = CyclePlan(cycleStart: date(9, 25))
        context.insert(octPlan)
        let hidup = PlanItem(name: "Hidup (Makan, bensin, emoney saldo)", amount: 938_300, kind: .envelope,
                             plan: octPlan,
                             envelopeCategories: ["Makan", "Bensin", "E-money"].compactMap { categories[$0] })
        let octTravelling = PlanItem(name: "Travelling", amount: 2_000_000, kind: .envelope, plan: octPlan)
        [hidup, octTravelling].forEach(context.insert)

        let novPlan = CyclePlan(cycleStart: date(10, 25))
        context.insert(novPlan)
        let novTravelling = PlanItem(name: "Travelling", amount: 2_000_000, kind: .envelope, plan: novPlan)
        context.insert(novTravelling)

        let seeded = [("Makan", Decimal(420_000)), ("Bensin", 191_400), ("E-money", 100_000)].map {
            Expense(amount: $0.1, date: date(9, 28), category: categories[$0.0])
        }
        let trip = [("Makan", Decimal(85_000), "Nasi Padang Bandung"), ("Bensin", 150_000, "Bensin ke Bandung"),
                    ("Sewa", 450_000, "Hotel Bandung")].map {
            Expense(amount: $0.1, date: date(9, 29), note: $0.2, category: categories[$0.0])
        }
        let gift = Expense(amount: 250_000, date: date(9, 29), note: "Kado ultah Tarisa", category: categories["Makan"])
        let ticket = Expense(amount: 1_200_000, date: date(10, 14, hour: 9), note: "Tiket KAI ke Jakarta",
                             category: categories["Transport"])
        (seeded + trip + [gift, ticket]).forEach(context.insert)
        trip.forEach { $0.envelope = octTravelling }
        gift.isOutsideEnvelopes = true
        ticket.envelope = novTravelling
        try context.save()

        return Sample(octPlan: octPlan, novPlan: novPlan, hidup: hidup, octTravelling: octTravelling,
                      novTravelling: novTravelling, categories: categories, seeded: seeded, trip: trip,
                      gift: gift, ticket: ticket)
    }

    private func detail(of envelope: PlanItem, cycle: PayCycle, expenses: [Expense]) -> EnvelopeDetail {
        let claims = EnvelopeClaims(envelopes: EnvelopeOffer.activeEnvelopes(of: envelope.plan), cycle: cycle)
        return EnvelopeDetail(envelope: envelope, claims: claims, cycleExpenses: expenses,
                              payday: payday, calendar: calendar)
    }

    private func spent(of envelope: PlanItem, cycle: PayCycle, expenses: [Expense]) throws -> Decimal {
        let all = EnvelopeSpend.progress(envelopes: EnvelopeOffer.activeEnvelopes(of: envelope.plan),
                                         cycleExpenses: expenses, cycle: cycle)
        return try XCTUnwrap(all.first { $0.itemID == envelope.persistentModelID }).spent
    }

    // MARK: - §4.4 What is listed

    /// T2: the trip, assigned by hand, though Hidup claims its Makan and Bensin.
    @MainActor
    func testAnAssignedEnvelopeListsItsAssignedExpenses() throws {
        let s = try sample(in: try makeInMemoryContext())
        let travelling = detail(of: s.octTravelling, cycle: october, expenses: s.october)

        XCTAssertEqual(travelling.sections.count, 1)
        XCTAssertFalse(travelling.sections[0].isPaidEarly)
        XCTAssertEqual(Set(travelling.expenses.map(\.note)),
                       ["Nasi Padang Bandung", "Bensin ke Bandung", "Hotel Bandung"])
        XCTAssertEqual(travelling.total, 685_000)
    }

    /// T3: Hidup lists what its Categories claim, minus the assigned trip and the gift.
    @MainActor
    func testAClaimingEnvelopeLeavesOutAssignedAndNoEnvelopeExpenses() throws {
        let s = try sample(in: try makeInMemoryContext())
        let hidup = detail(of: s.hidup, cycle: october, expenses: s.october)

        XCTAssertEqual(Set(hidup.expenses.map(\.persistentModelID)), Set(s.seeded.map(\.persistentModelID)))
        XCTAssertFalse(hidup.expenses.contains(s.gift))
        XCTAssertFalse(hidup.expenses.contains { s.trip.contains($0) })
        XCTAssertEqual(hidup.total, 711_400)
    }

    /// A Fixed item's expense is From plan already and never sits in an envelope.
    @MainActor
    func testAFixedItemsExpenseIsNeverListed() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let pulsa = PlanItem(name: "Pulsa Ibu", amount: 100_000, kind: .fixed, plan: s.octPlan,
                             category: s.categories["Makan"])
        context.insert(pulsa)
        let done = Expense(amount: 100_000, date: date(10, 1), category: s.categories["Makan"], planItem: pulsa)
        context.insert(done)
        try context.save()

        let hidup = detail(of: s.hidup, cycle: october, expenses: s.october + [done])
        XCTAssertFalse(hidup.expenses.contains(done))
    }

    /// An expense of this cycle paid early into a later one is counted there, not here.
    @MainActor
    func testAnExpensePaidEarlyOutOfThisCycleIsNotListedHere() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let bekal = Expense(amount: 60_000, date: date(10, 13), note: "Bekal kereta", category: s.categories["Makan"])
        context.insert(bekal)
        bekal.envelope = s.novTravelling
        try context.save()

        let hidup = detail(of: s.hidup, cycle: october, expenses: s.october + [bekal])
        XCTAssertFalse(hidup.expenses.contains(bekal))
        XCTAssertEqual(hidup.total, 711_400)
    }

    /// T4: November's own ledger has nothing for Travelling; the ticket arrives as paid
    /// early, in a section for October.
    @MainActor
    func testPaidEarlyExpensesFollowInTheirCyclesSection() throws {
        let s = try sample(in: try makeInMemoryContext())
        let travelling = detail(of: s.novTravelling, cycle: november, expenses: [])

        XCTAssertEqual(travelling.sections.count, 1)
        let section = travelling.sections[0]
        XCTAssertTrue(section.isPaidEarly)
        XCTAssertEqual(section.cycle, october)
        XCTAssertEqual(section.cycle.title(calendar: calendar), "October 2026")
        XCTAssertEqual(section.expenses, [s.ticket])
    }

    /// Own cycle first, then each earlier cycle newest first, days newest first inside.
    @MainActor
    func testSectionsRunOwnCycleThenEarlierCyclesNewestFirst() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let hotel = Expense(amount: 900_000, date: date(9, 20), note: "Hotel Jakarta", category: s.categories["Sewa"])
        let snack = Expense(amount: 40_000, date: date(10, 20), note: "Snack", category: s.categories["Makan"])
        let taxi = Expense(amount: 120_000, date: date(10, 28), note: "Taksi", category: s.categories["Transport"])
        [hotel, snack, taxi].forEach(context.insert)
        [hotel, snack, taxi].forEach { $0.envelope = s.novTravelling }
        try context.save()

        let travelling = detail(of: s.novTravelling, cycle: november, expenses: [taxi])

        XCTAssertEqual(travelling.sections.map(\.isPaidEarly), [false, true, true])
        XCTAssertEqual(travelling.sections.map { $0.cycle.title(calendar: calendar) },
                       ["November 2026", "October 2026", "September 2026"])
        XCTAssertEqual(travelling.sections[1].expenses.map(\.note), ["Snack", "Tiket KAI ke Jakarta"])
        XCTAssertEqual(travelling.sections[2].expenses, [hotel])
    }

    /// Goal 3: the list totals exactly what the bar says, in every sample.
    @MainActor
    func testTheListTotalsTheBarsSpentFigure() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let snack = Expense(amount: 40_000, date: date(10, 20), category: s.categories["Makan"])
        let taxi = Expense(amount: 120_000, date: date(10, 28), category: s.categories["Transport"])
        [snack, taxi].forEach(context.insert)
        [snack, taxi].forEach { $0.envelope = s.novTravelling }
        try context.save()

        for (envelope, cycle, expenses) in [(s.hidup, october, s.october), (s.octTravelling, october, s.october),
                                            (s.novTravelling, november, [taxi])] {
            XCTAssertEqual(detail(of: envelope, cycle: cycle, expenses: expenses).total,
                           try spent(of: envelope, cycle: cycle, expenses: expenses), envelope.name)
        }
    }

    // MARK: - §4.3, §4.5 Words

    @MainActor
    func testTheClaimsLineNamesCategoriesOrSaysAssignedOnly() throws {
        let s = try sample(in: try makeInMemoryContext())
        XCTAssertEqual(EnvelopeDetail.claimsLine(for: s.hidup), "Bensin · E-money · Makan")
        XCTAssertEqual(EnvelopeDetail.claimsLine(for: s.novTravelling), "Assigned expenses only")
    }

    /// T5, T6.
    @MainActor
    func testTheEmptyMessageDependsOnWhatTheEnvelopeClaims() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let pulsa = PlanItem(name: "Pulsa", amount: 50_000, kind: .envelope, plan: s.novPlan,
                             envelopeCategories: [try XCTUnwrap(s.categories["Pulsa"])])
        context.insert(pulsa)

        XCTAssertTrue(detail(of: pulsa, cycle: november, expenses: []).isEmpty)
        XCTAssertEqual(EnvelopeDetail.emptyTitle(for: s.hidup), "Nothing in Hidup (Makan, bensin, emoney saldo) yet")
        XCTAssertEqual(EnvelopeDetail.emptyMessage(for: s.hidup),
                       "Bensin, E-money and Makan expenses this cycle land here by themselves.")
        XCTAssertEqual(EnvelopeDetail.emptyMessage(for: pulsa), "Pulsa expenses this cycle land here by themselves.")
        XCTAssertEqual(EnvelopeDetail.emptyTitle(for: s.novTravelling), "Nothing in Travelling yet")
        XCTAssertEqual(EnvelopeDetail.emptyMessage(for: s.novTravelling),
                       "Only expenses you assign land here. Use ＋ to add one or move some in.")
    }

    // MARK: - §4.6 Reopening

    @MainActor
    func testTheDetailReopensOnlyForAnActiveEnvelope() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        XCTAssertTrue(EnvelopeDetail.canReopen(s.hidup))

        let reminder = PlanItem(name: "Liburan Saving", amount: 0, kind: .envelope, carriedOver: true, plan: s.novPlan)
        context.insert(reminder)
        try context.save()
        XCTAssertFalse(EnvelopeDetail.canReopen(reminder), "dormant")

        context.delete(s.hidup)
        try context.save()
        XCTAssertFalse(EnvelopeDetail.canReopen(s.hidup), "deleted")
    }
}
