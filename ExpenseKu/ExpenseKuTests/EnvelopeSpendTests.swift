//
//  EnvelopeSpendTests.swift
//  ExpenseKuTests
//
//  The envelope accounting rule from PRD §5.2, which has no screen and is the single
//  easiest thing in this feature to get wrong: an expense created by a Fixed PlanItem
//  is excluded from every envelope, whatever its Category. Without that, a completed
//  "Kos" is counted again inside the "Hidup" envelope sharing its Group and the plan
//  reports the same money twice.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class EnvelopeSpendTests: XCTestCase {

    /// An envelope totals the expenses whose Category is in its set.
    @MainActor
    func testSpentSumsTheCategoriesInTheSet() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        let bensin = Category(name: "Bensin")
        let kopi = Category(name: "Kopi")
        [makan, bensin, kopi].forEach(context.insert)
        let envelope = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                envelopeCategories: [makan, bensin])
        context.insert(envelope)

        let expenses = [Expense(amount: 500_000, category: makan),
                        Expense(amount: 211_400, category: bensin),
                        Expense(amount: 90_000, category: kopi)]
        expenses.forEach(context.insert)
        try context.save()

        let progress = try XCTUnwrap(EnvelopeSpend.progress(envelopes: [envelope],
                                                            cycleExpenses: expenses).first)
        XCTAssertEqual(progress.spent, 711_400, "Kopi is in no envelope and is simply unbudgeted")
        XCTAssertEqual(progress.remainder, 226_900)
        XCTAssertFalse(progress.isOver)
    }

    /// **§5.2.** An expense linked to a Fixed PlanItem never counts toward an
    /// envelope, even when its Category is squarely in the set.
    @MainActor
    func testAnExpenseFromAFixedItemIsExcluded() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        context.insert(makan)
        let fixed = PlanItem(name: "Kos", amount: 2_200_000, category: makan)
        let envelope = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                envelopeCategories: [makan])
        context.insert(fixed)
        context.insert(envelope)

        let fromPlan = Expense(amount: 2_200_000, category: makan, planItem: fixed)
        let ordinary = Expense(amount: 120_000, category: makan)
        context.insert(fromPlan)
        context.insert(ordinary)
        try context.save()

        let progress = try XCTUnwrap(EnvelopeSpend.progress(
            envelopes: [envelope], cycleExpenses: [fromPlan, ordinary]).first)
        XCTAssertEqual(progress.spent, 120_000)
    }

    /// Overspend fills past the track rather than clamping, and the remainder flips
    /// to how far over it has gone.
    @MainActor
    func testOverspendIsReportedNotClamped() throws {
        let context = try makeInMemoryContext()
        let jajan = Category(name: "Jajan")
        context.insert(jajan)
        let envelope = PlanItem(name: "Jajan Kantor", amount: 193_900, kind: .envelope,
                                envelopeCategories: [jajan])
        context.insert(envelope)
        let expenses = [Expense(amount: 242_200, category: jajan)]
        expenses.forEach(context.insert)
        try context.save()

        let progress = try XCTUnwrap(EnvelopeSpend.progress(
            envelopes: [envelope], cycleExpenses: expenses).first)
        XCTAssertTrue(progress.isOver)
        XCTAssertEqual(progress.remainder, 48_300)
        XCTAssertEqual(progress.overspend, 48_300)
        XCTAssertGreaterThan(progress.fraction, 1)
    }

    /// An envelope planned at zero has no bar to draw, and must not divide by zero.
    @MainActor
    func testAZeroEnvelopeHasNoFractionRatherThanInfinity() throws {
        let context = try makeInMemoryContext()
        let kopi = Category(name: "Kopi")
        context.insert(kopi)
        let envelope = PlanItem(name: "Baru", amount: 0, kind: .envelope,
                                envelopeCategories: [kopi])
        context.insert(envelope)
        let expenses = [Expense(amount: 50_000, category: kopi)]
        expenses.forEach(context.insert)
        try context.save()

        let progress = try XCTUnwrap(EnvelopeSpend.progress(
            envelopes: [envelope], cycleExpenses: expenses).first)
        XCTAssertEqual(progress.fraction, 0)
        XCTAssertTrue(progress.fraction.isFinite)
    }

    /// The F4 picker excludes categories another envelope in this plan already claims,
    /// but never the envelope currently being edited — its own picks must stay
    /// selectable.
    @MainActor
    func testClaimsExcludeTheEnvelopeBeingEdited() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        let kopi = Category(name: "Kopi")
        [makan, kopi].forEach(context.insert)
        let hidup = PlanItem(name: "Hidup", amount: 1, kind: .envelope, envelopeCategories: [makan])
        let jajan = PlanItem(name: "Jajan Kantor", amount: 1, kind: .envelope, envelopeCategories: [kopi])
        context.insert(hidup)
        context.insert(jajan)
        try context.save()

        let claims = EnvelopeSpend.claims(in: [hidup, jajan], excluding: jajan)
        XCTAssertEqual(claims[makan.persistentModelID], "Hidup")
        XCTAssertNil(claims[kopi.persistentModelID], "Jajan Kantor's own pick stays available to it")
    }
}
