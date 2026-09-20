//
//  GroupSharesTests.swift
//  ExpenseKuTests
//
//  The plan's percentage table (PRD §6.1.5). Planned figures only, percentages
//  display-only, and the one rule the PRD never wrote down: what an Envelope whose
//  categories span two Groups attributes to.
//

import XCTest
import SwiftData
@testable import ExpenseKu

private typealias Category = ExpenseKu.Category

nonisolated final class GroupSharesTests: XCTestCase {

    /// Each Group's planned total as a share of income, biggest first.
    @MainActor
    func testSharesAreOfTotalIncome() throws {
        let context = try makeInMemoryContext()
        let obligations = CategoryGroup(name: "Fixed Obligations")
        let housing = CategoryGroup(name: "Housing & Living")
        [obligations, housing].forEach(context.insert)
        let cicilan = Category(name: "Cicilan", group: obligations)
        let kos = Category(name: "Kos", group: housing)
        [cicilan, kos].forEach(context.insert)
        let items = [PlanItem(name: "Cicilan Rumah BNI", amount: 12_406_000, category: cicilan),
                     PlanItem(name: "Kos", amount: 3_429_500, category: kos)]
        items.forEach(context.insert)
        try context.save()

        let rows = GroupShares.rows(activeItems: items, totalIncome: 22_000_000)
        XCTAssertEqual(rows.map(\.groupName), ["Fixed Obligations", "Housing & Living"])
        XCTAssertEqual(rows[0].share, 0.5639, accuracy: 0.0001)
        XCTAssertEqual(rows[1].planned, 3_429_500)
    }

    /// An item with no Group — or no Category at all — lands in "Ungrouped", which
    /// always sorts last however much it holds: it is the absence of an answer.
    @MainActor
    func testUngroupedSortsLastWhateverItHolds() throws {
        let context = try makeInMemoryContext()
        let housing = CategoryGroup(name: "Housing & Living")
        context.insert(housing)
        let kos = Category(name: "Kos", group: housing)
        let loose = Category(name: "Lain-lain")
        [kos, loose].forEach(context.insert)
        let items = [PlanItem(name: "Kos", amount: 1_000_000, category: kos),
                     PlanItem(name: "Misc", amount: 9_000_000, category: loose),
                     PlanItem(name: "No category", amount: 500_000)]
        items.forEach(context.insert)
        try context.save()

        let rows = GroupShares.rows(activeItems: items, totalIncome: 20_000_000)
        XCTAssertEqual(rows.map(\.groupName), ["Housing & Living", GroupShares.ungroupedName])
        XCTAssertEqual(rows.last?.planned, 9_500_000)
    }

    /// An Envelope attributes wholly to the Group most of its categories belong to —
    /// splitting the amount would invent a division the owner never made.
    @MainActor
    func testAnEnvelopeAttributesToItsModalGroup() throws {
        let context = try makeInMemoryContext()
        let housing = CategoryGroup(name: "Housing & Living")
        let transport = CategoryGroup(name: "Transportation & Travel")
        [housing, transport].forEach(context.insert)
        let makan = Category(name: "Makan", group: housing)
        let galon = Category(name: "Galon", group: housing)
        let bensin = Category(name: "Bensin", group: transport)
        [makan, galon, bensin].forEach(context.insert)
        let envelope = PlanItem(name: "Hidup", amount: 938_300, kind: .envelope,
                                envelopeCategories: [makan, galon, bensin])
        context.insert(envelope)
        try context.save()

        let rows = GroupShares.rows(activeItems: [envelope], totalIncome: 22_000_000)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].groupName, "Housing & Living")
        XCTAssertEqual(rows[0].planned, 938_300)
    }

    /// An envelope whose categories are all ungrouped is itself ungrouped, not a
    /// crash and not an arbitrary pick.
    @MainActor
    func testAnEnvelopeWithNoGroupedCategoryIsUngrouped() throws {
        let context = try makeInMemoryContext()
        let kopi = Category(name: "Kopi")
        context.insert(kopi)
        let envelope = PlanItem(name: "Jajan", amount: 100_000, kind: .envelope,
                                envelopeCategories: [kopi])
        context.insert(envelope)
        try context.save()
        XCTAssertNil(GroupShares.group(of: envelope))
    }

    /// A plan with no income yet still renders its amounts; the percentages are just
    /// zero rather than a division by zero.
    @MainActor
    func testZeroIncomeGivesZeroSharesNotInfinity() throws {
        let context = try makeInMemoryContext()
        let item = PlanItem(name: "Kos", amount: 2_200_000)
        context.insert(item)
        try context.save()
        let rows = GroupShares.rows(activeItems: [item], totalIncome: 0)
        XCTAssertEqual(rows.first?.share, 0)
        XCTAssertEqual(rows.first?.planned, 2_200_000)
    }

    /// The table's amounts add up to Total Cost — the check the owner is making when
    /// they read it.
    @MainActor
    func testSharesSumToTotalCost() throws {
        let context = try makeInMemoryContext()
        let group = CategoryGroup(name: "Housing & Living")
        context.insert(group)
        let kos = Category(name: "Kos", group: group)
        context.insert(kos)
        let items = [PlanItem(name: "a", amount: 2_200_000, category: kos),
                     PlanItem(name: "b", amount: 200_000),
                     PlanItem(name: "c", amount: 650_000, category: kos)]
        items.forEach(context.insert)
        try context.save()

        let rows = GroupShares.rows(activeItems: items, totalIncome: 20_000_000)
        XCTAssertEqual(rows.reduce(Decimal(0)) { $0 + $1.planned }, 3_050_000)
    }
}
