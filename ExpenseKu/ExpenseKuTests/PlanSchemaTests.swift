//
//  PlanSchemaTests.swift
//  ExpenseKuTests
//
//  That the V2 schema actually opens, and that its two riskiest shapes hold.
//
//  A model layer can compile perfectly and still fail at ModelContainer construction,
//  so "it builds" proves nothing here. Two things in particular were worth pinning
//  before any UI was written on top of them:
//
//  1. PlanItem holds *two distinct* relationships to Category — `category` (the Fixed
//     item's single one) and `envelopeCategories` (the envelope's set). SwiftData only
//     accepts that when each has its own explicit inverse.
//  2. Every delete rule behaves as ADR-0001 and PRD §9.4/§9.5 require, including the
//     one place this feature cascades.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class PlanSchemaTests: XCTestCase {

    /// The V2 container opens with all nine models, both PlanItem→Category
    /// relationships included.
    @MainActor
    func testV2ContainerOpens() throws {
        let context = try makeInMemoryContext()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanItem>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CyclePlan>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CategoryGroup>()), 0)
    }

    /// A Fixed item's `category` and an envelope's `envelopeCategories` are independent:
    /// writing one never disturbs the other.
    @MainActor
    func testTheTwoCategoryRelationshipsAreIndependent() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        let bensin = Category(name: "Bensin")
        context.insert(makan)
        context.insert(bensin)

        let fixed = PlanItem(name: "Kos", amount: 2_200_000, kind: .fixed, category: makan)
        let envelope = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                envelopeCategories: [makan, bensin])
        context.insert(fixed)
        context.insert(envelope)
        try context.save()

        XCTAssertEqual(fixed.category?.name, "Makan")
        XCTAssertEqual(fixed.envelopeCategories?.count, 0)
        XCTAssertEqual(envelope.envelopeCategories?.count, 2)
        XCTAssertNil(envelope.category)
        // Makan is claimed by one envelope and named by one Fixed item at once.
        XCTAssertEqual(makan.envelopes?.count, 1)
    }

    /// PRD §9.5: deleting an Expense returns its PlanItem to not-done. Derived from
    /// the link, so no code runs — which is the point.
    @MainActor
    func testDeletingTheExpenseReturnsTheItemToNotDone() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Kos", amount: 2_200_000)
        let expense = Expense(amount: 2_200_000, note: "Kos", planItem: item)
        context.insert(item)
        context.insert(expense)
        try context.save()
        XCTAssertTrue(item.isDone)

        context.delete(expense)
        try context.save()
        XCTAssertFalse(item.isDone)
    }

    /// PRD §9.4 / ADR-0001: deleting a PlanItem leaves its Expense as history and
    /// only drops the link.
    @MainActor
    func testDeletingThePlanItemKeepsTheExpense() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Cicilan", amount: 4_700_000)
        let expense = Expense(amount: 4_750_000, note: "Cicilan", planItem: item)
        context.insert(item)
        context.insert(expense)
        try context.save()

        context.delete(item)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 1)
        XCTAssertNil(expense.planItem)
    }

    /// Deleting a plan cascades to its own parts — they have no meaning without it —
    /// but the cascade stops dead at the Expense boundary, which is the invariant
    /// ADR-0001 actually protects.
    @MainActor
    func testDeletingAPlanCascadesToItsPartsButNeverToTheLedger() throws {
        let context = try makeInMemoryContext()
        let plan = CyclePlan(cycleStart: .now)
        let item = PlanItem(name: "Kos", amount: 2_200_000, plan: plan)
        let income = IncomeLine(name: "Gaji", amount: 20_000_000, plan: plan)
        let expense = Expense(amount: 2_200_000, note: "Kos", planItem: item)
        context.insert(plan)
        context.insert(item)
        context.insert(income)
        context.insert(expense)
        try context.save()

        context.delete(plan)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanItem>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<IncomeLine>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Expense>()), 1)
    }

    /// Deleting a Category leaves every envelope that claimed it intact, merely
    /// narrower (ADR-0001 nullify).
    @MainActor
    func testDeletingACategoryNarrowsTheEnvelopeRatherThanRemovingIt() throws {
        let context = try makeInMemoryContext()
        let makan = Category(name: "Makan")
        let bensin = Category(name: "Bensin")
        let envelope = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                envelopeCategories: [makan, bensin])
        context.insert(makan)
        context.insert(bensin)
        context.insert(envelope)
        try context.save()

        context.delete(makan)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PlanItem>()), 1)
        XCTAssertEqual(envelope.envelopeCategories?.count, 1)
    }

    /// Deleting a group leaves its categories ungrouped, never deleted.
    @MainActor
    func testDeletingAGroupUngroupsItsCategories() throws {
        let context = try makeInMemoryContext()
        let group = CategoryGroup(name: "Housing & Living")
        let kos = Category(name: "Kos", group: group)
        context.insert(group)
        context.insert(kos)
        try context.save()
        XCTAssertEqual(group.categories?.count, 1)

        context.delete(group)
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Category>()), 1)
        XCTAssertNil(kos.group)
    }

    /// An unrecognised kind — a value a future version wrote and synced down — reads
    /// as Fixed. A Fixed item is inert until ticked, where an envelope would silently
    /// start absorbing expenses.
    @MainActor
    func testAnUnknownKindReadsAsFixed() throws {
        let item = PlanItem(name: "?", amount: 0)
        item.kindRaw = "something-from-the-future"
        XCTAssertEqual(item.kind, .fixed)
    }
}
