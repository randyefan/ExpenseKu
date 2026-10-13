//
//  EnvelopeGatherTests.swift
//  ExpenseKuTests
//
//  Flow R (docs/prd/envelope-assignment.md §4.8, §4.9): what a row's long-press can
//  move, and what "Move expenses here…" offers.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class EnvelopeGatherTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private let payday = 25

    private func date(_ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: m, day: d, hour: 12)) ?? .distantPast
    }

    /// **§4.9.** Everything in the cycle that does not count in Travelling now —
    /// claimed by Hidup, Outside plan, No envelope, or assigned elsewhere — newest
    /// first; never what is already there, never a Fixed item's expense, never
    /// another cycle's.
    @MainActor
    func testMoveExpensesHereOffersEverythingNotAlreadyCountingThere() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        let sewa = Category(name: "Sewa")
        [makan, sewa].forEach(context.insert)
        let plan = CyclePlan(cycleStart: date(9, 25))
        context.insert(plan)
        let hidup = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope, plan: plan, envelopeCategories: [makan])
        let travelling = PlanItem(name: "Travelling", amount: 2_000_000, kind: .envelope, plan: plan)
        let kos = PlanItem(name: "Kos", amount: 2_200_000, plan: plan, category: sewa)
        [hidup, travelling, kos].forEach(context.insert)

        let lunch = Expense(amount: 45_000, date: date(10, 10), note: "Lunch", category: makan)
        let hotel = Expense(amount: 450_000, date: date(10, 12), note: "Hotel", category: sewa)
        let nasi = Expense(amount: 85_000, date: date(10, 11), note: "Nasi", category: makan)
        let gift = Expense(amount: 250_000, date: date(10, 13), note: "Gift", category: makan)
        let rent = Expense(amount: 2_200_000, date: date(10, 5), note: "Rent", category: sewa, planItem: kos)
        [lunch, hotel, nasi, gift, rent].forEach(context.insert)
        EnvelopeChoice.envelope(travelling.persistentModelID).apply(to: nasi, envelopes: [travelling])
        EnvelopeChoice.noEnvelope.apply(to: gift, envelopes: [])
        try context.save()

        let claims = EnvelopeClaims(envelopes: [hidup, travelling],
                                    cycle: PayCycle.containing(date(10, 1), payday: payday, calendar: calendar))
        let all = [lunch, hotel, nasi, gift, rent]
        XCTAssertEqual(EnvelopeGather.candidates(for: travelling, cycleExpenses: all, claims: claims).map(\.note),
                       ["Gift", "Hotel", "Lunch"])
        XCTAssertEqual(EnvelopeGather.candidates(for: hidup, cycleExpenses: all, claims: claims).map(\.note),
                       ["Gift", "Hotel", "Nasi"], "Nasi is assigned to Travelling, so Hidup may take it back")
    }

    /// **§4.8.** A row offers Move to envelope… only when its own cycle's plan, or a
    /// later one on offer, has an active envelope, and never for a Fixed item's expense.
    @MainActor
    func testARowCanMoveOnlyWhenItsOwnCycleHasAnEnvelope() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        context.insert(makan)
        let october = CyclePlan(cycleStart: date(9, 25))
        let november = CyclePlan(cycleStart: date(10, 25))
        [october, november].forEach(context.insert)
        context.insert(PlanItem(name: "Travelling", amount: 2_000_000, kind: .envelope, plan: october))
        let kos = PlanItem(name: "Kos", amount: 2_200_000, plan: november)
        context.insert(kos)
        let inOctober = Expense(amount: 85_000, date: date(10, 12), category: makan)
        let inNovember = Expense(amount: 30_000, date: date(10, 30), category: makan)
        let fromFixed = Expense(amount: 2_200_000, date: date(10, 5), planItem: kos)
        [inOctober, inNovember, fromFixed].forEach(context.insert)
        try context.save()

        let origins = PlanOrigins(plans: [october, november], payday: payday, calendar: calendar)
        let now = date(10, 14)
        XCTAssertEqual(origins.moveTarget(for: inOctober, now: now),
                       PayCycle.containing(date(10, 12), payday: payday, calendar: calendar))
        XCTAssertNil(origins.moveTarget(for: inNovember, now: now), "November's plan has no envelope, and October's is behind it")
        XCTAssertNil(origins.moveTarget(for: fromFixed, now: now))
    }
}
