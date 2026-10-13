//
//  EnvelopeAssignmentTests.swift
//  ExpenseKuTests
//
//  docs/prd/envelope-assignment.md §4.1, §4.2, §4.7 and §5.4, against the PRD's own
//  sample (§7): the normal plan's Hidup and Kebutuhan Kos, plus a Travelling envelope
//  that claims no Category and lives on assigned expenses alone.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class EnvelopeAssignmentTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let payday = 25

    private func date(_ m: Int, _ d: Int, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: m, day: d, hour: 12)) ?? .distantPast
    }

    private struct Sample {
        let plan: CyclePlan
        let hidup: PlanItem
        let kos: PlanItem
        let travelling: PlanItem
        let makan: Category
        let bensin: Category
        let sewa: Category
        let seeded: [Expense]
        let trip: [Expense]
        let gift: Expense
        var all: [Expense] { seeded + trip + [gift] }
    }

    @MainActor
    private func sample(in context: ModelContext) throws -> Sample {
        let names = ["Makan", "Bensin", "E-money", "Tisu", "Sabun", "Galon", "Sewa"]
        let categories = Dictionary(uniqueKeysWithValues: names.map { ($0, Category(name: $0)) })
        categories.values.forEach(context.insert)

        let plan = CyclePlan(cycleStart: date(9, 25))
        context.insert(plan)
        let hidup = PlanItem(name: "Hidup (Makan, bensin, emoney saldo)", amount: 938_300, kind: .envelope,
                             plan: plan, envelopeCategories: ["Makan", "Bensin", "E-money"].compactMap { categories[$0] })
        let kos = PlanItem(name: "Kebutuhan Kos di Jkt (Tisu, sabun, galon)", amount: 193_900, kind: .envelope,
                           plan: plan, envelopeCategories: ["Tisu", "Sabun", "Galon"].compactMap { categories[$0] })
        let travelling = PlanItem(name: "Travelling", amount: 2_000_000, kind: .envelope, plan: plan)
        [hidup, kos, travelling].forEach(context.insert)

        let seeded = [("Makan", Decimal(420_000)), ("Bensin", 191_400), ("E-money", 100_000),
                      ("Tisu", 92_200), ("Sabun", 80_000), ("Galon", 70_000)].map {
            Expense(amount: $0.1, date: date(9, 28), category: categories[$0.0])
        }
        let trip = [("Makan", Decimal(85_000), "Nasi Padang Bandung"),
                    ("Bensin", 150_000, "Bensin ke Bandung"),
                    ("Sewa", 450_000, "Hotel Bandung")].map {
            Expense(amount: $0.1, date: date(10, 12), note: $0.2, category: categories[$0.0])
        }
        let gift = Expense(amount: 250_000, date: date(10, 13), note: "Kado ultah Tarisa", category: categories["Makan"])
        (seeded + trip + [gift]).forEach(context.insert)
        trip.forEach { EnvelopeChoice.envelope(travelling.persistentModelID).apply(to: $0, envelopes: [travelling]) }
        EnvelopeChoice.noEnvelope.apply(to: gift, envelopes: [])
        try context.save()

        return Sample(plan: plan, hidup: hidup, kos: kos, travelling: travelling,
                      makan: try XCTUnwrap(categories["Makan"]), bensin: try XCTUnwrap(categories["Bensin"]),
                      sewa: try XCTUnwrap(categories["Sewa"]), seeded: seeded, trip: trip, gift: gift)
    }

    private func progress(_ s: Sample, _ envelope: PlanItem) throws -> EnvelopeProgress {
        let all = EnvelopeSpend.progress(envelopes: [s.hidup, s.kos, s.travelling], cycleExpenses: s.all)
        return try XCTUnwrap(all.first { $0.itemID == envelope.persistentModelID })
    }

    // MARK: - §4.1 Where an expense counts

    /// **The assigned envelope wins over the claiming one.** Nasi Padang and Bensin ke
    /// Bandung are Makan and Bensin, both claimed by Hidup, yet only Travelling counts
    /// them — and Hidup stays exactly where the seed left it.
    @MainActor
    func testAnAssignedExpenseCountsInItsEnvelopeOnly() throws {
        let s = try sample(in: try makeInMemoryContext())

        XCTAssertEqual(try progress(s, s.travelling).spent, 685_000)
        XCTAssertEqual(try progress(s, s.travelling).remainderText, "Rp\u{00A0}1.315.000 left")
        XCTAssertEqual(try progress(s, s.hidup).spent, 711_400)
        XCTAssertEqual(try progress(s, s.hidup).remainderText, "Rp\u{00A0}226.900 left")
        XCTAssertEqual(try progress(s, s.kos).remainderText, "Rp\u{00A0}48.300 over")
    }

    /// **No envelope** takes a Makan out of Hidup and out of the plan altogether.
    @MainActor
    func testNoEnvelopeCountsNowhereAndFallsOutsidePlan() throws {
        let s = try sample(in: try makeInMemoryContext())
        let origins = PlanOrigins(plans: [s.plan], payday: payday, calendar: calendar)

        XCTAssertNil(origins.origin(of: s.gift))
        XCTAssertEqual(origins.origin(of: s.trip[0]), .envelope(name: "Travelling"))
        XCTAssertEqual(origins.origin(of: s.seeded[0]), .envelope(name: "Hidup (Makan, bensin, emoney saldo)"))
        XCTAssertEqual(origins.origin(of: s.trip[2]), .envelope(name: "Travelling"), "Sewa is claimed by no envelope")
    }

    /// The header split and the plan filter read the same rule, so the filtered rows
    /// still add up to the lit legend figure.
    @MainActor
    func testTheSplitAndThePlanFilterFollowTheAssignment() throws {
        let s = try sample(in: try makeInMemoryContext())
        let origins = PlanOrigins(plans: [s.plan], payday: payday, calendar: calendar)
        let cycle = PayCycle.containing(date(10, 1), payday: payday, calendar: calendar)

        let split = origins.split(s.all, in: cycle)
        XCTAssertEqual(split.outsidePlan, 250_000, "only the gift; Hotel Bandung's Sewa is assigned")
        XCTAssertEqual(split.fromPlan, 953_600 + 685_000)

        let outside = origins.expenses(s.all, in: cycle, matching: .outsidePlan)
        XCTAssertEqual(outside.map(\.note), ["Kado ultah Tarisa"])
        let fromPlan = origins.expenses(s.all, in: cycle, matching: .fromPlan)
        XCTAssertEqual(fromPlan.reduce(0) { $0 + $1.amount }, split.fromPlan)
    }

    /// **The guard.** An assignment to an envelope of another cycle's plan is ignored
    /// and the expense falls back to its Category — what a payday change leaves behind.
    @MainActor
    func testAnAssignmentToAnotherCyclesEnvelopeIsIgnored() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let november = CyclePlan(cycleStart: date(10, 25))
        context.insert(november)
        let hidupNov = PlanItem(name: "Hidup", amount: 900_000, kind: .envelope, plan: november,
                                envelopeCategories: [])
        context.insert(hidupNov)
        let strayed = Expense(amount: 30_000, date: date(10, 30), category: s.makan)
        context.insert(strayed)
        EnvelopeChoice.envelope(s.travelling.persistentModelID).apply(to: strayed, envelopes: [s.travelling])
        try context.save()

        let origins = PlanOrigins(plans: [s.plan, november], payday: payday, calendar: calendar)
        XCTAssertNil(origins.origin(of: strayed), "November's Hidup claims no Makan, and October's Travelling does not count")

        let spent = EnvelopeSpend.progress(envelopes: [hidupNov], cycleExpenses: [strayed])
        XCTAssertEqual(spent.first?.spent, 0)
    }

    /// An expense a Fixed item created stays out of every envelope, even if an
    /// assignment somehow reached it.
    @MainActor
    func testAFixedItemsExpenseIgnoresAnAssignment() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let kosFixed = PlanItem(name: "Kos", amount: 2_200_000, plan: s.plan, category: s.sewa)
        context.insert(kosFixed)
        let rent = Expense(amount: 2_200_000, date: date(10, 5), category: s.sewa, planItem: kosFixed)
        context.insert(rent)
        rent.envelope = s.travelling
        try context.save()

        let spent = EnvelopeSpend.progress(envelopes: [s.travelling], cycleExpenses: s.all + [rent])
        XCTAssertEqual(spent.first?.spent, 685_000)
    }

    // MARK: - §4.2, §5.4

    /// Travelling claims no Category and still fills, and an envelope holding assigned
    /// spending is in use even at Rp 0 planned.
    @MainActor
    func testAnEnvelopeWithAssignedSpendingIsNeverDormant() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        s.travelling.amount = 0
        s.travelling.carriedOver = true
        let empty = PlanItem(name: "Liburan Saving", amount: 0, kind: .envelope, carriedOver: true, plan: s.plan)
        context.insert(empty)
        try context.save()

        XCTAssertFalse(PlanDormancy.isDormant(s.travelling))
        XCTAssertTrue(PlanDormancy.isDormant(empty))
    }

    /// Carry-over copies the envelope, not what was assigned to it.
    @MainActor
    func testCarryOverCopiesTheEnvelopeButNotItsAssignments() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        let next = PayCycle.containing(date(10, 30), payday: payday, calendar: calendar)
        let copy = try XCTUnwrap(PlanCarryOver.makePlan(for: next, from: [s.plan], in: context))

        let travelling = try XCTUnwrap(copy.items?.first { $0.name == "Travelling" })
        XCTAssertEqual(travelling.assignedExpenses ?? [], [])
        XCTAssertEqual(s.travelling.assignedExpenses?.count, 3)
    }

    // MARK: - §4.7 Deleting an envelope

    @MainActor
    func testDeletingAnEnvelopeReturnsItsExpensesToCountingByCategory() throws {
        let context = try makeInMemoryContext()
        let s = try sample(in: context)
        XCTAssertEqual(PlanCopy.deleteItemBody(amount: nil, date: nil,
                                               assignedCount: s.travelling.assignedExpenses?.count ?? 0),
                       "3 expenses assigned to it stay in your ledger and go back to counting by category.")
        XCTAssertEqual(PlanCopy.deleteItemBody(amount: nil, date: nil, assignedCount: 1),
                       "1 expense assigned to it stays in your ledger and goes back to counting by category.")

        context.delete(s.travelling)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 10)
        XCTAssertTrue(s.trip.allSatisfy { $0.envelope == nil })
        let origins = PlanOrigins(plans: [s.plan], payday: payday, calendar: calendar)
        XCTAssertEqual(origins.origin(of: s.trip[0]), .envelope(name: "Hidup (Makan, bensin, emoney saldo)"))
        XCTAssertNil(origins.origin(of: s.trip[2]), "Sewa is claimed by no envelope")
    }
}
