//
//  PlanDormancyTests.swift
//  ExpenseKuTests
//
//  Which carried-over rows fold away, and the order the rest sit in (PRD §7.2, §9.1).
//
//  The first test is the one that matters. PRD §7.2's wording says "Rp 0 **or** never
//  completed", which read literally folds every freshly copied row — including
//  Cicilan Rumah BNI at Rp 7.706.000 — into a collapsed section the instant the owner
//  pages forward. CONTEXT.md's AND reading is the ubiquitous language and the one
//  implemented; this file is where that is pinned.
//

import XCTest
import SwiftData
@testable import ExpenseKu

nonisolated final class PlanDormancyTests: XCTestCase {

    /// **A carried-over item with money against it is never dormant**, however
    /// incomplete it is.
    @MainActor
    func testACarriedItemWithAnAmountIsNotDormant() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Cicilan Rumah BNI", amount: 7_706_000, carriedOver: true)
        context.insert(item)
        XCTAssertFalse(PlanDormancy.isDormant(item))
    }

    /// A carried row at Rp 0 that was never completed folds away — the spreadsheet's
    /// "don't forget Liburan Saving" reminders.
    @MainActor
    func testACarriedZeroRowIsDormant() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Liburan Saving", amount: 0, carriedOver: true)
        context.insert(item)
        XCTAssertTrue(PlanDormancy.isDormant(item))
    }

    /// A row the owner is halfway through typing stays where they can see it.
    @MainActor
    func testAFreshlyTypedZeroRowIsNotDormant() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "", amount: 0, carriedOver: false)
        context.insert(item)
        XCTAssertFalse(PlanDormancy.isDormant(item))
    }

    /// A Rp 0 row that was actually completed is history, not a reminder.
    @MainActor
    func testACompletedZeroRowIsNotDormant() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Refund", amount: 0, carriedOver: true)
        let expense = Expense(amount: 0, planItem: item)
        context.insert(item)
        context.insert(expense)
        try context.save()
        XCTAssertFalse(PlanDormancy.isDormant(item))
    }

    /// Amount descending, matching the spreadsheet.
    @MainActor
    func testSortIsAmountDescending() throws {
        let context = try makeInMemoryContext()
        let items = [PlanItem(name: "Netflix", amount: 130_000),
                     PlanItem(name: "Kos", amount: 2_200_000),
                     PlanItem(name: "Listrik", amount: 200_000)]
        items.forEach(context.insert)
        XCTAssertEqual(PlanDormancy.sorted(items).map(\.name), ["Kos", "Listrik", "Netflix"])
    }

    /// Equal amounts break on name then creation order, so the list does not shuffle
    /// between launches or disagree between devices.
    @MainActor
    func testEqualAmountsSortStably() throws {
        let context = try makeInMemoryContext()
        let early = Date(timeIntervalSince1970: 1)
        let late = Date(timeIntervalSince1970: 2)
        let items = [PlanItem(name: "Vidio", amount: 59_000, createdAt: late),
                     PlanItem(name: "Apple Service", amount: 59_000, createdAt: early),
                     PlanItem(name: "Apple Service", amount: 59_000, createdAt: late)]
        items.forEach(context.insert)
        let sorted = PlanDormancy.sorted(items)
        XCTAssertEqual(sorted.map(\.name), ["Apple Service", "Apple Service", "Vidio"])
        XCTAssertEqual(sorted[0].createdAt, early)
    }

    /// The split hands back two sorted lists, not one filtered twice.
    @MainActor
    func testSplitSortsBothSides() throws {
        let context = try makeInMemoryContext()
        let items = [PlanItem(name: "Kos", amount: 2_200_000, carriedOver: true),
                     PlanItem(name: "Liburan Saving", amount: 0, carriedOver: true),
                     PlanItem(name: "New year occasion", amount: 0, carriedOver: true)]
        items.forEach(context.insert)
        let split = PlanDormancy.split(items)
        XCTAssertEqual(split.active.map(\.name), ["Kos"])
        XCTAssertEqual(split.dormant.map(\.name), ["Liburan Saving", "New year occasion"])
    }
}
