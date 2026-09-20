//
//  PlanTotalsTests.swift
//  ExpenseKuTests
//
//  The arithmetic at the head of a plan, and the one invariant the whole feature
//  rests on: Sisa sums *planned* figures and never subtracts an expense (PRD §9.9,
//  ADR-0005). If that ever stops holding, the number drifts down all month and looks
//  entirely plausible the whole way — which is why it gets a test that changes only
//  the expenses and asserts nothing moved.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class PlanTotalsTests: XCTestCase {

    @MainActor
    private func makeTotals(
        items: [PlanItem], income: [IncomeLine], envelopes: [EnvelopeProgress] = []
    ) -> PlanTotals {
        PlanTotals(activeItems: items, incomeLines: income, envelopes: envelopes)
    }

    /// Sisa is Total income − Total cost, over planned amounts only.
    @MainActor
    func testSisaIsIncomeMinusPlannedCost() throws {
        let context = try makeInMemoryContext()
        let income = [IncomeLine(name: "Gaji", amount: 20_000_000),
                      IncomeLine(name: "THR", amount: 2_000_000)]
        let items = [PlanItem(name: "Kos", amount: 15_000_000),
                     PlanItem(name: "Hidup", amount: 5_000_000, kind: .envelope)]
        income.forEach(context.insert)
        items.forEach(context.insert)

        let totals = makeTotals(items: items, income: income)
        XCTAssertEqual(totals.totalIncome, 22_000_000)
        XCTAssertEqual(totals.totalCost, 20_000_000)
        XCTAssertEqual(totals.sisa, 2_000_000)
    }

    /// **The ADR-0005 invariant.** Logging expenses against the plan's categories
    /// changes Sisa by exactly nothing. Only editing the plan moves it.
    @MainActor
    func testSisaDoesNotMoveWhenMoneyIsActuallySpent() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        context.insert(makan)
        let income = [IncomeLine(name: "Gaji", amount: 20_000_000)]
        let fixed = PlanItem(name: "Kos", amount: 2_200_000, category: makan)
        let envelope = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                envelopeCategories: [makan])
        income.forEach(context.insert)
        context.insert(fixed)
        context.insert(envelope)

        let before = makeTotals(items: [fixed, envelope], income: income).sisa

        // Money actually moves: the Fixed item completes at a different figure, and
        // the envelope absorbs a pile of ordinary expenses.
        let actual = Expense(amount: 2_500_000, note: "Kos", category: makan, planItem: fixed)
        context.insert(actual)
        let loose = (1...5).map { _ in Expense(amount: 200_000, category: makan) }
        loose.forEach(context.insert)
        try context.save()

        let envelopes = EnvelopeSpend.progress(envelopes: [envelope], cycleExpenses: loose + [actual])
        let after = makeTotals(items: [fixed, envelope], income: income, envelopes: envelopes)

        XCTAssertEqual(after.sisa, before, "Sisa is a plan figure, not a balance")
        XCTAssertEqual(after.totalCost, 3_138_300)
    }

    /// Drift over Fixed items is signed: an item that came in under offsets one that
    /// came in over, which is what "over plan so far" means as a net.
    @MainActor
    func testFixedDriftIsSignedAndNets() throws {
        let context = try makeInMemoryContext()
        let over = PlanItem(name: "Tagihan Ibu", amount: 280_000)
        let under = PlanItem(name: "Listrik", amount: 200_000)
        context.insert(over)
        context.insert(under)
        context.insert(Expense(amount: 407_500, planItem: over))     // +127.500
        context.insert(Expense(amount: 150_000, planItem: under))    //  −50.000
        try context.save()

        let totals = makeTotals(items: [over, under], income: [])
        XCTAssertEqual(totals.drift, 77_500)
        XCTAssertTrue(totals.showsDrift)
    }

    /// Envelope drift is clamped at zero. An envelope with room left is unspent
    /// allowance, not underspend — netting it would make the figure meaningless
    /// halfway through a cycle.
    @MainActor
    func testEnvelopeDriftCountsOverspendOnly() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope)
        context.insert(item)

        let under = EnvelopeProgress(itemID: item.persistentModelID, planned: 938_300, spent: 711_400)
        XCTAssertEqual(makeTotals(items: [item], income: [], envelopes: [under]).drift, 0)

        let over = EnvelopeProgress(itemID: item.persistentModelID, planned: 193_900, spent: 242_200)
        XCTAssertEqual(makeTotals(items: [item], income: [], envelopes: [over]).drift, 48_300)
    }

    /// Nothing done, nothing spent: no drift strip.
    @MainActor
    func testNoDriftBeforeAnythingHappens() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Kos", amount: 2_200_000)
        context.insert(item)
        let totals = makeTotals(items: [item], income: [IncomeLine(name: "Gaji", amount: 20_000_000)])
        XCTAssertEqual(totals.drift, 0)
        XCTAssertFalse(totals.showsDrift)
        XCTAssertFalse(totals.showsOverIncome)
    }

    /// A plan that allocates past its income shows the over-income strip, and the two
    /// strips are independent — this one is about the plan, the other about actuals.
    @MainActor
    func testNegativeSisaShowsOverIncomeAndNothingElse() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Kasih farah uang liburan", amount: 21_480_000)
        context.insert(item)
        let totals = makeTotals(items: [item], income: [IncomeLine(name: "Gaji", amount: 20_000_000)])
        XCTAssertEqual(totals.sisa, -1_480_000)
        XCTAssertTrue(totals.showsOverIncome)
        XCTAssertFalse(totals.showsDrift)
    }

    /// An empty plan is all zeroes, not a crash and not a negative.
    @MainActor
    func testAnEmptyPlanIsZero() {
        let totals = makeTotals(items: [], income: [])
        XCTAssertEqual(totals.totalIncome, 0)
        XCTAssertEqual(totals.totalCost, 0)
        XCTAssertEqual(totals.sisa, 0)
        XCTAssertFalse(totals.showsOverIncome)
    }
}
